final: prev:
let
  # Create the text of a znc config file, so that it can be securely
  # deployed to a NixOS host without putting it in the Nix store.
  #
  # XXX dhess - this is a hack and should be revisited.
  mkZncConfig = (import ../modules/services/znc/conf.nix);

  # Make NixOps deployments buildable in Hydra.
  deployments = network:
    final.recurseIntoAttrs
      (
        final.lib.mapAttrs (final.lib.const (n: n.config.system.build.toplevel))
          network.nodes
      );
  network = nixops: import (nixops + "/nix/eval-machine-info.nix");

  # A slightly extended version of darwinSystem that automatically
  # appends the hacknix modules to the modules provided in the args.
  darwinSystemWithArgs = args: system:
    let
      config = system args;
    in
    final.lib.hacknix.flake.inputs.nix-darwin.lib.darwinSystem (config // {
      modules = (config.modules or [ ]) ++ [
        final.lib.hacknix.flake.darwinModule
      ];
    });

  importDarwinConfigurations = dir: args:
    final.lib.mapAttrs
      (_: config: darwinSystemWithArgs args config)
      (final.lib.sources.importDirectory dir);

  # A slightly extended version of nixosSystem that automatically
  # appends the hacknix modules to the modules provided by the
  # configuration.
  nixosSystemWithArgs = args: system:
    let
      config = system args;
    in
    final.lib.hacknix.flake.inputs.nixpkgs.lib.nixosSystem (config // {
      modules = (config.modules or [ ]) ++ [
        final.lib.hacknix.flake.nixosModule
      ];
    });

  importNixosConfigurations = dir: args:
    final.lib.mapAttrs
      (_: config: nixosSystemWithArgs args config)
      (final.lib.sources.importDirectory dir);

  # A convenience function for importing directories full of NixOS
  # Python-style tests.
  importNixosTests = dir: { system, pkgs, extraConfigurations ? [ ] }: testArgs:
    let
      testingPython = import (final.lib.hacknix.flake.inputs.nixpkgs + "/nixos/lib/testing-python.nix") {
        inherit system pkgs extraConfigurations;
      };
      callTest = test: test ({ inherit testingPython; } // testArgs);
    in
    final.lib.mapAttrs (_: test: callTest test)
      (final.lib.sources.importDirectory dir);


in
{
  lib = (prev.lib or { }) // {
    hacknix = (prev.lib.hacknix or { }) // {
      path = ../..;

      inherit mkZncConfig;

      inherit darwinSystemWithArgs;
      inherit importDarwinConfigurations;

      inherit nixosSystemWithArgs;
      inherit importNixosConfigurations;

      inherit importNixosTests;

      nixops = (prev.lib.hacknix.nixops or { }) // {
        inherit deployments network;
      };
    };
  };
}
