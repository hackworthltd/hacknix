{
  description = "Hackworth Ltd Nix.";

  inputs = {
    nixpkgs.url = "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz";

    nix-darwin.url = "https://github.com/nix-darwin/nix-darwin/archive/master.tar.gz";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "https://github.com/NixOS/flake-compat/archive/master.tar.gz";
    flake-compat.flake = false;

    gitignore-nix.url = "https://github.com/hercules-ci/gitignore.nix/archive/master.tar.gz";
    gitignore-nix.flake = false;

    treefmt-nix.url = "https://github.com/numtide/treefmt-nix/archive/main.tar.gz";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks-nix.url = "https://github.com/cachix/git-hooks.nix/archive/master.tar.gz";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "https://github.com/hercules-ci/flake-parts/archive/main.tar.gz";
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
            inherit (pkgs) niks3;
          };

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
          pkgsFor =
            system:
            import inputs.nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                allowBroken = true;
              };
              overlays = [ inputs.self.overlays.default ];
            };
          pkgs = pkgsFor "x86_64-linux";
          aarch64-darwin-pkgs = pkgsFor "aarch64-darwin";
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
                    };

                    hacknix = (prev.lib.hacknix or { }) // {
                      flake = (prev.lib.hacknix.flake or { }) // {
                        inherit inputs;
                        inherit (inputs.self) darwinModules;
                      };
                    };
                  };
                })
                overlaysFromDir
              ];
          };

          darwinModules = {
            default = {
              imports = [
                ./nix/darwinModules/config/defaults/default.nix
                ./nix/darwinModules/config/defaults/nix.nix
                ./nix/darwinModules/config/remote-builds/build-host
                ./nix/darwinModules/config/remote-builds/remote-build-host

                ./nix/darwinModules/programs/git
              ];
              nixpkgs.overlays = [ inputs.self.overlays.default ];
            };
          };

          # This is convenient for using this flake's utilities
          # downstream.
          inherit (pkgs) lib;

          x86_64-linux-ci =
            let
              packages = inputs.self.packages.x86_64-linux;
              checks = inputs.self.checks.x86_64-linux;
              devShells = inputs.self.devShells.x86_64-linux;
            in
            pkgs.lib.flakes.recurseIntoHydraJobs {
              inherit
                packages
                checks
                devShells
                ;
              required = pkgs.releaseTools.aggregate {
                name = "required";
                constituents = builtins.map builtins.attrValues ([
                  packages
                  checks
                  devShells
                ]);
                meta.description = "Required x86_64-linux CI builds";
              };
            };

          aarch64-darwin-ci =
            let
              packages = inputs.self.packages.aarch64-darwin;
              checks = inputs.self.checks.aarch64-darwin;
              devShells = inputs.self.devShells.aarch64-darwin;
            in
            aarch64-darwin-pkgs.lib.flakes.recurseIntoHydraJobs {
              inherit
                packages
                checks
                devShells
                ;
              required = aarch64-darwin-pkgs.releaseTools.aggregate {
                name = "required";
                constituents = builtins.map builtins.attrValues ([
                  packages
                  checks
                  devShells
                ]);
                meta.description = "Required aarch64-darwin CI builds";
              };
            };
        };
    };
}
