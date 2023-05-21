{
  description = "Hackworth Ltd Nix.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nix-darwin.url = github:LnL7/nix-darwin;

    flake-compat.url = github:edolstra/flake-compat;
    flake-compat.flake = false;

    gitignore-nix.url = github:hercules-ci/gitignore.nix;
    gitignore-nix.flake = false;

    nixos-generators.url = github:nix-community/nixos-generators;
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks-nix.url = github:cachix/pre-commit-hooks.nix;
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@ { flake-parts, ... }:
    let
    in
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        debug = true;

        imports = [
          inputs.pre-commit-hooks-nix.flakeModule
        ];
        systems = [ "x86_64-linux" "aarch64-darwin" ];

        perSystem = { config, pkgs, system, ... }: {
          # We need a `pkgs` that includes our own overlays within
          # `perSystem`. This isn't done by default, so we do this
          # workaround. See:
          #
          # https://github.com/hercules-ci/flake-parts/issues/106#issuecomment-1399041045
          _module.args.pkgs = import inputs.nixpkgs
            {
              inherit system;
              config = {
                allowUnfree = true;
                allowBroken = true;
              };
              overlays = [ inputs.self.overlays.default ];
            };

          pre-commit = {
            check.enable = true;
            settings = {
              src = ./.;
              hooks = {
                nixpkgs-fmt.enable = true;

                prettier = {
                  enable = true;
                  excludes = [ ".github/" ];
                };

                actionlint = {
                  enable = true;
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
              ];
            };
          };

          packages = {
            inherit (pkgs) nmrpflash;

            inherit (pkgs) ffdhe2048Pem ffdhe3072Pem ffdhe4096Pem;

            inherit (pkgs) cachix-archive-flake-inputs cachix-push-attr cachix-push-flake-dev-shell;

            # These aren't actually derivations, and therefore, we
            # can't export them from packages. They are in the overlay, however.
            # inherit (pkgs) gitignoreSource gitignoreFilter;
            # inherit (pkgs) lib;
          } // (pkgs.lib.optionalAttrs (system == "x86_64-linux")
            (
              let
                nixosGenerators =
                  pkgs.lib.flakes.nixosGenerators.importFromDirectory
                    pkgs.lib.hacknix.nixosGenerate
                    ./examples/nixos
                    {
                      inherit pkgs;
                      format = "lxc";
                    };

              in
              {
                inherit (nixosGenerators) remote-build-host build-host;

                inherit (pkgs) containerlab;
              }
            )
          ) // (pkgs.lib.optionalAttrs (system == "aarch64-darwin")
            {
              inherit (pkgs) tart;
            }
          );

          apps =
            let
              mkApp = pkg: script: {
                type = "app";
                program = "${pkg}/bin/${script}";
              };
            in
            (pkgs.lib.mapAttrs (name: pkg: mkApp pkg name) {
              inherit (pkgs)
                cachix-archive-flake-inputs
                cachix-push-attr
                cachix-push-flake-dev-shell;
            });

          devShells.default = pkgs.mkShell {
            buildInputs = (with pkgs;
              [
                actionlint
                nodePackages.prettier
                nixpkgs-fmt
                nil
              ]);


            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };

        flake =
          let
            # See above, we need to use our own `pkgs` within the flake.
            pkgs = import inputs.nixpkgs
              {
                system = "x86_64-linux";
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
                  ./nix/modules/config/providers/ec2/default.nix
                  ./nix/modules/config/providers/linode/default.nix
                  ./nix/modules/config/providers/vultr/cloud/default.nix

                  ./nix/modules/config/defaults/default.nix
                  ./nix/modules/config/defaults/acme.nix
                  ./nix/modules/config/defaults/environment.nix
                  ./nix/modules/config/defaults/networking.nix
                  ./nix/modules/config/defaults/nginx.nix
                  ./nix/modules/config/defaults/nix.nix
                  ./nix/modules/config/defaults/security.nix
                  ./nix/modules/config/defaults/ssh.nix
                  ./nix/modules/config/defaults/sudo.nix
                  ./nix/modules/config/defaults/system.nix
                  ./nix/modules/config/defaults/tmux.nix
                  ./nix/modules/config/defaults/users.nix

                  ./nix/modules/config/services/freeradius

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

                  ./nix/modules/core/module-hashes.nix

                  ./nix/modules/dns/unbound-multi-instance

                  ./nix/modules/networking/accept
                  ./nix/modules/networking/virtual-ips

                  ./nix/modules/services/tarsnapper
                  ./nix/modules/services/tftpd-hpa
                  ./nix/modules/services/vault/agent

                  ./nix/common/config/services/vault/agent/auth/approle
                  ./nix/common/config/services/vault/agent/template
                  ./nix/common/config/services/vault/agent/template/aws-credentials
                  ./nix/common/config/services/vault/agent/template/cachix
                  ./nix/common/config/services/vault/agent/template/flyctl
                  ./nix/common/config/services/vault/agent/template/github-credentials
                  ./nix/common/config/services/vault/agent/template/netrc
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
                  ./nix/common/config/services/vault/agent/template/cachix
                  ./nix/common/config/services/vault/agent/template/flyctl

                  ./nix/common/config/services/vault/agent/template/github-credentials

                  ./nix/common/config/services/vault/agent/template/netrc
                ];
                nixpkgs.overlays = [ inputs.self.overlays.default ];
              };
            };

            nixosConfigurations =
              let
                extraModules = [{
                  boot.isContainer = true;
                }];
                mkSystem = pkgs.lib.hacknix.nixosSystem' extraModules;
              in
              pkgs.lib.flakes.nixosConfigurations.importFromDirectory
                mkSystem
                ./examples/nixos
                {
                  inherit (pkgs) lib;
                };

            darwinConfigurations =
              pkgs.lib.flakes.darwinConfigurations.importFromDirectory
                pkgs.lib.hacknix.darwinSystem
                ./examples/nix-darwin
                {
                  inherit (pkgs) lib;
                };

            # This is convenient for using this flake's utilities
            # downstream.
            inherit (pkgs) lib;

            hydraJobs = {
              inherit (inputs.self) checks;
              inherit (inputs.self) packages;
              inherit (inputs.self) devShells;

              nixosConfigurations = pkgs.lib.flakes.nixosConfigurations.build
                inputs.self.nixosConfigurations;

              darwinConfigurations = pkgs.lib.flakes.darwinConfigurations.build
                inputs.self.darwinConfigurations;

              # Bespoke tests which don't fit into `checks`, because
              # they depend on the nixpkgs release-lib framework.
              tests = {
                tests =
                  (pkgs.lib.testing.nixos.importFromDirectory ./tests/fixtures
                    {
                      hostPkgs = pkgs;
                      defaults.imports = [ inputs.self.nixosModules.default ];
                    }
                  )
                  // (with import (inputs.nixpkgs + "/pkgs/top-level/release-lib.nix")
                    {
                      supportedSystems = [ "x86_64-linux" ];
                      scrubJobs = true;
                      nixpkgsArgs = {
                        config = {
                          allowUnfree = false;
                          allowBroken = true;
                          inHydra = true;
                        };
                        overlays = [
                          inputs.self.overlays.default
                          (import ./lib-tests)
                        ];
                      };
                    };
                  mapTestOn {
                    dlnAttrSets = all;
                    dlnIPAddr = all;
                    dlnMisc = all;
                    dlnFfdhe = all;
                    dlnTypes = all;
                  });
              };

              required = pkgs.releaseTools.aggregate {
                name = "required-nix-ci";
                constituents = builtins.map builtins.attrValues (with inputs.self.hydraJobs; [
                  packages.x86_64-linux
                  packages.aarch64-darwin
                  checks.x86_64-linux
                  checks.aarch64-darwin

                  nixosConfigurations
                  darwinConfigurations

                  # These don't evaluate correctly for some reason.

                  #tests
                ]);
                meta.description = "Required Nix CI builds";
              };
            };

            ciJobs = pkgs.lib.flakes.recurseIntoHydraJobs inputs.self.hydraJobs;
          };
      };
}
