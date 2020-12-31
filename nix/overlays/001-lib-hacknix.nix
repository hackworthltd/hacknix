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

  # Like their hacknix-lib equivalents, except these automatically
  # append the hacknix modules (or darwinModules) to the
  # configuration.
  nixosSystem' = extraModules:
    final.lib.flakes.nixosSystem' ([ final.lib.hacknix.flake.nixosModule ] ++ extraModules);
  nixosSystem = nixosSystem' [ ];
  amazonImage = extraModules:
    final.lib.flakes.amazonImage ([ final.lib.hacknix.flake.nixosModule ] ++ extraModules);
  isoImage = extraModules:
    final.lib.flakes.isoImage ([ final.lib.hacknix.flake.nixosModule ] ++ extraModules);
  darwinSystem' = extraModules:
    final.lib.flakes.darwinSystem' ([ final.lib.hacknix.flake.darwinModule ] ++ extraModules);
  darwinSystem = darwinSystem' [ ];

in
{
  lib = (prev.lib or { }) // {
    hacknix = (prev.lib.hacknix or { }) // {
      path = ../..;

      inherit mkZncConfig;

      inherit nixosSystem' nixosSystem amazonImage isoImage;
      inherit darwinSystem' darwinSystem;

      nixops = (prev.lib.hacknix.nixops or { }) // {
        inherit deployments network;
      };
    };
  };
}
