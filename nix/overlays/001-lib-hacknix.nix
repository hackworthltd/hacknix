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

  # A version of the nixosSystem function that automatically appends
  # the hacknix modules, so that the configuration doesn't need to do
  # that manually.
  nixosSystem = final.lib.flakes.nixosSystem' [ final.lib.hacknix.flake.nixosModule ];

  # A version of nixosConfigurations.importFromDirectory that
  # automatically injects the hacknix modules into each system
  # configuration.
  importFromDirectory =
    final.lib.flakes.nixosConfigurations.importFromDirectory nixosSystem;

  # A version of the darwinSystem function that automatically appends
  # the hacknix darwin modules, so that the configuration doesn't need to do
  # that manually.
  darwinSystem = final.lib.flakes.darwinSystem' [ final.lib.hacknix.flake.darwinModule ];

in
{
  lib = (prev.lib or { }) // {
    hacknix = (prev.lib.hacknix or { }) // {
      path = ../..;

      inherit mkZncConfig;

      inherit nixosSystem;
      nixosConfigurations = (prev.lib.hacknix.nixosConfigurations or { }) // {
        inherit importFromDirectory;
      };

      inherit darwinSystem;
      darwinConfigurations = (prev.lib.hacknix.darwinConfigurations or { }) // {
        importFromDirectory =
          final.lib.flakes.nixosConfigurations.importFromDirectory darwinSystem;
      };

      nixops = (prev.lib.hacknix.nixops or { }) // {
        inherit deployments network;
      };
    };
  };
}
