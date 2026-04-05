{
  description = "Hackworth Ltd Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    gitignore-nix.url = "github:hercules-ci/gitignore.nix";
    gitignore-nix.flake = false;

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;

      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        let
          nixfmt-ignores = [
            "lib-tests/test-dir/foo.nix"
            "lib-tests/test-dir/nix/bar.nix"
            "lib-tests/test-dir/src/bar.nix"
            "lib-tests/test-dir/src/.#bar.nix"
          ];
        in
        {
          # We need a `pkgs` that includes our own overlays within
          # `perSystem`. This isn't done by default, so we do this
          # workaround. See:
          #
          # https://github.com/hercules-ci/flake-parts/issues/106#issuecomment-1399041045
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowBroken = true;
            };
            overlays = [ inputs.self.overlays.default ];
          };

          formatter = pkgs.nixfmt-rfc-style;

          pre-commit = {
            check.enable = true;
            settings = {
              src = ./.;
              hooks = {
                treefmt.enable = true;
                nixfmt-rfc-style.enable = true;

                prettier = {
                  enable = true;
                };

                actionlint = {
                  # https://github.com/hackworthltd/hacknix/issues/827
                  enable = false;
                  name = "actionlint";
                  entry = "${pkgs.actionlint}/bin/actionlint";
                  language = "system";
                  files = "^.github/workflows/";
                };
              };

              excludes = [
                "CODE_OF_CONDUCT.md"
                "LICENSE"
                ".buildkite/"
                "flake.lock"
              ]
              ++ nixfmt-ignores;
            };
          };

          packages = {
            # These aren't actually derivations, and therefore, we
            # can't export them from packages. They are in the overlay, however.
            # inherit (pkgs) gitignoreSource gitignoreFilter;
            # inherit (pkgs) lib;

            inherit (pkgs) niks3;
          }
          // (pkgs.lib.optionalAttrs (system == "x86_64-linux") (
            let
              lxc =
                pkgs.lib.flakes.nixosGenerators.importFromDirectory pkgs.lib.hacknix.nixosGenerate ./examples/nixos
                  {
                    format = "lxc";
                  };

              qcow =
                pkgs.lib.flakes.nixosGenerators.importFromDirectory pkgs.lib.hacknix.nixosGenerate ./examples/nixos
                  {
                    format = "qcow";
                  };

            in
            {
              remote-build-host-lxc = lxc.remote-build-host;
              build-host-lxc = lxc.build-host;

              # Disabled until we have `kvm` support in CI again.

              #remote-build-host-qcow = qcow.remote-build-host;
              #build-host-qcow = qcow.build-host;
            }
          ));

          treefmt.config = {
            projectRootFile = "flake.nix";
            programs = {
              prettier.enable = true;
              nixfmt.enable = true;
            };
            settings.formatter.nixfmt.excludes = nixfmt-ignores;
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [
              config.treefmt.build.devShell
            ];

            buildInputs = (
              with pkgs;
              [
                # https://github.com/hackworthltd/hacknix/issues/827
                #actionlint
                prettier
                nixd
                nodejs
                vscode-langservers-extracted
                nixfmt-rfc-style
              ]
            );

            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };

      flake =
        let
          # See above, we need to use our own `pkgs` within the flake.
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config = {
              allowUnfree = true;
              allowBroken = true;
            };
            overlays = [ inputs.self.overlays.default ];
          };
          aarch64-darwin-pkgs = import inputs.nixpkgs {
            system = "aarch64-darwin";
            config = {
              allowUnfree = true;
              allowBroken = true;
            };
            overlays = [ inputs.self.overlays.default ];
          };
        in
        {
          overlays = {
            default =
              let
                bootstrap = (import ./nix/overlays/000-bootstrap.nix) { } inputs.nixpkgs;
                overlaysFromDir = bootstrap.lib.overlays.combineFromDir ./nix/overlays;
              in
              bootstrap.lib.overlays.combine [
                (final: prev: {
                  lib = (prev.lib or { }) // {

                    flakes = (prev.lib.flakes or { }) // {
                      # For some reason, the nixpkgs flake doesn't roll its local
                      # lib.nixosSystem into nixpkgs.lib. We expose it here.
                      inherit (inputs.nixpkgs.lib) nixosSystem;

                      # Ditto for nix-darwin's lib.darwinSystem function.
                      inherit (inputs.nix-darwin.lib) darwinSystem;

                      inherit (inputs.nixos-generators) nixosGenerate;
                    };

                    hacknix = (prev.lib.hacknix or { }) // {
                      flake = (prev.lib.hacknix.flake or { }) // {
                        inherit inputs;
                        inherit (inputs.self) darwinModules;
                        inherit (inputs.self) nixosModules;
                      };
                    };
                  };
                })
                overlaysFromDir
              ];
          };

          nixosModules = {
            # Ideally, this would be refactored into multiple stand-alone
            # modules, but many of these modules are interdependent at the
            # moment, so we simply export them as a single module, for now.
            default = {
              imports = [
                ./nix/modules/config/defaults/default.nix
                ./nix/modules/config/defaults/acme.nix
                ./nix/modules/config/defaults/environment.nix
                ./nix/modules/config/defaults/networking.nix
                ./nix/modules/config/defaults/nix.nix
                ./nix/modules/config/defaults/security.nix
                ./nix/modules/config/defaults/ssh.nix
                ./nix/modules/config/defaults/sudo.nix
                ./nix/modules/config/defaults/system.nix
                ./nix/modules/config/defaults/tmux.nix
                ./nix/modules/config/defaults/users.nix

                ./nix/modules/config/hardware/amd/common.nix
                ./nix/modules/config/hardware/amd/jaguar.nix
                ./nix/modules/config/hardware/apu2/apu3c4.nix
                ./nix/modules/config/hardware/intel/broadwell-de.nix
                ./nix/modules/config/hardware/intel/centerton.nix
                ./nix/modules/config/hardware/intel/coffee-lake.nix
                ./nix/modules/config/hardware/intel/common.nix
                ./nix/modules/config/hardware/intel/haswell.nix
                ./nix/modules/config/hardware/intel/kaby-lake.nix
                ./nix/modules/config/hardware/intel/sandy-bridge.nix
                ./nix/modules/config/hardware/smartd/1x-non-removable.nix
                ./nix/modules/config/hardware/smartd/2x-non-removable.nix
                ./nix/modules/config/hardware/smartd/36x-hotswap.nix
                ./nix/modules/config/hardware/smartd/4x-hotswap.nix
                ./nix/modules/config/hardware/supermicro/sys-5017a-ef.nix
                ./nix/modules/config/hardware/supermicro/sys-5018d-fn4t.nix
                ./nix/modules/config/hardware/supermicro/sys-5018d-mtln4f.nix
                ./nix/modules/config/hardware/supermicro/mb-x10.nix
                ./nix/modules/config/hardware/hwutils.nix
                ./nix/modules/config/hardware/mbr.nix
                ./nix/modules/config/hardware/uefi.nix

                ./nix/modules/config/networking/tcp-bbr

                ./nix/modules/config/nix/auto-gc

                ./nix/modules/config/remote-builds/remote-build-host
                ./nix/modules/config/remote-builds/build-host

                ./nix/modules/networking/accept
                ./nix/modules/networking/virtual-ips

                ./nix/modules/services/tftpd-hpa
                ./nix/modules/services/vault/agent

                ./nix/common/config/services/vault/agent/auth/approle
                ./nix/common/config/services/vault/agent/template
                ./nix/common/config/services/vault/agent/template/aws-credentials
                ./nix/common/config/services/vault/agent/template/aws-sts-credentials
                ./nix/common/config/services/vault/agent/template/cachix
                ./nix/common/config/services/vault/agent/template/github-credentials
                ./nix/common/config/services/vault/agent/template/netrc
                ./nix/common/config/services/vault/agent/template/remote-builder-ssh
                ./nix/common/config/services/vault/agent/template/ssh-ca-host-key
                ./nix/common/core/module-hashes.nix
              ];
              nixpkgs.overlays = [ inputs.self.overlays.default ];
            };
          };

          darwinModules = {
            default = {
              imports = [
                ./nix/darwinModules/config/defaults/default.nix
                ./nix/darwinModules/config/defaults/nix.nix
                ./nix/darwinModules/config/remote-builds/build-host
                ./nix/darwinModules/config/remote-builds/remote-build-host

                ./nix/darwinModules/config/services/vault-agent

                ./nix/darwinModules/programs/git

                ./nix/common/config/services/vault/agent/auth/approle
                ./nix/common/config/services/vault/agent/template
                ./nix/common/config/services/vault/agent/template/aws-credentials
                ./nix/common/config/services/vault/agent/template/aws-sts-credentials
                ./nix/common/config/services/vault/agent/template/cachix
                ./nix/common/config/services/vault/agent/template/github-credentials
                ./nix/common/config/services/vault/agent/template/netrc
                ./nix/common/config/services/vault/agent/template/remote-builder-ssh
                ./nix/common/config/services/vault/agent/template/ssh-ca-host-key
                ./nix/common/core/module-hashes.nix
              ];
              nixpkgs.overlays = [ inputs.self.overlays.default ];
            };
          };

          nixosConfigurations =
            let
              extraModules = [
                {
                  boot.isContainer = true;
                }
              ];
              mkSystem = pkgs.lib.hacknix.nixosSystem' extraModules;
            in
            pkgs.lib.flakes.nixosConfigurations.importFromDirectory mkSystem ./examples/nixos {
              inherit (pkgs) lib;
            };

          darwinConfigurations =
            pkgs.lib.flakes.darwinConfigurations.importFromDirectory pkgs.lib.hacknix.darwinSystem
              ./examples/nix-darwin
              {
                inherit (pkgs) lib;
              };

          # This is convenient for using this flake's utilities
          # downstream.
          inherit (pkgs) lib;

          x86_64-linux-ci =
            let
              packages = inputs.self.packages.x86_64-linux;
              checks = inputs.self.checks.x86_64-linux;
              devShells = inputs.self.devShells.x86_64-linux;
              nixosConfigurations = pkgs.lib.flakes.nixosConfigurations.build inputs.self.nixosConfigurations;
            in
            pkgs.lib.flakes.recurseIntoHydraJobs {
              inherit
                packages
                checks
                devShells
                nixosConfigurations
                ;
              required = pkgs.releaseTools.aggregate {
                name = "required-x86_64-linux";
                constituents = builtins.map builtins.attrValues ([
                  packages
                  checks
                  devShells
                  nixosConfigurations
                ]);
                meta.description = "Required x86_64-linux CI builds";
              };
            };

          aarch64-darwin-ci =
            let
              packages = inputs.self.packages.aarch64-darwin;
              checks = inputs.self.checks.aarch64-darwin;
              devShells = inputs.self.devShells.aarch64-darwin;
              darwinConfigurations = pkgs.lib.flakes.darwinConfigurations.build inputs.self.darwinConfigurations;
            in
            pkgs.lib.flakes.recurseIntoHydraJobs {
              inherit
                packages
                checks
                devShells
                darwinConfigurations
                ;
              required = aarch64-darwin-pkgs.releaseTools.aggregate {
                name = "required-aarch64-darwin";
                constituents = builtins.map builtins.attrValues ([
                  packages
                  checks
                  devShells
                  darwinConfigurations
                ]);
                meta.description = "Required aarch64-darwin CI builds";
              };
            };
        };
    };
}
