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

  # Given a set of remote build hosts of the hacknix remoteBuildHost
  # type, create SSH config for the remote build host hostname and
  # port.
  sshExtraConfig = remoteBuildHosts:
    let
      mkHostPortPairs = remoteBuildHosts:
        final.lib.mapAttrsToList
          (_: descriptor: with descriptor; { inherit hostName port; })
          remoteBuildHosts;
    in
    final.lib.concatMapStrings
      (
        pair:
        final.lib.optionalString (pair.port != null) ''

        Host ${pair.hostName}
        Port ${toString pair.port}
      ''
      )
      (mkHostPortPairs remoteBuildHosts);

  # Given a set of remote build hosts of the hacknix remoteBuildHost
  # type, create an SSH known hosts config that can be used as a value
  # for `programs.ssh.knownHosts`.
  knownHosts = remoteBuildHosts:
    final.lib.mapAttrs'
      (
        host: descriptor: final.lib.nameValuePair host {
          hostNames = final.lib.singleton descriptor.hostName
            ++ descriptor.alternateHostNames;
          publicKey = descriptor.hostPublicKeyLiteral;
        }
      )
      remoteBuildHosts;

in
{
  lib = (prev.lib or { }) // {
    hacknix = (prev.lib.hacknix or { }) // {
      path = ../..;

      inherit mkZncConfig;

      inherit nixosSystem' nixosSystem amazonImage isoImage;
      inherit darwinSystem' darwinSystem;

      remote-build-host = (prev.lib.hacknix.remote-build-host or { }) // {
        inherit sshExtraConfig;
        inherit knownHosts;
      };

      nixops = (prev.lib.hacknix.nixops or { }) // {
        inherit deployments network;
      };
    };
  };
}
