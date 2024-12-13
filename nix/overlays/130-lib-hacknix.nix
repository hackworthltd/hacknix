final: prev:
let
  hacknixExtraModules = [
    final.lib.hacknix.flake.nixosModules.default
  ];

  # Like their lib.flakes equivalents, except these automatically
  # append the hacknix modules (or darwinModules) to the
  # configuration.
  nixosSystem' = extraModules: final.lib.flakes.nixosSystem' (hacknixExtraModules ++ extraModules);
  nixosSystem = nixosSystem' [ ];
  amazonImage = extraModules: final.lib.flakes.amazonImage (hacknixExtraModules ++ extraModules);
  isoImage = extraModules: final.lib.flakes.isoImage (hacknixExtraModules ++ extraModules);
  darwinSystem' =
    extraModules:
    final.lib.flakes.darwinSystem' ([ final.lib.hacknix.flake.darwinModules.default ] ++ extraModules);
  darwinSystem = darwinSystem' [ ];
  nixosGenerate' =
    extraModules: final.lib.flakes.nixosGenerate' (hacknixExtraModules ++ extraModules);
  nixosGenerate = nixosGenerate' [ ];

  # Given a set of remote build hosts of the hacknix remoteBuildHost
  # type, create SSH config for the remote build host hostname and
  # port.
  sshExtraConfig =
    remoteBuildHosts:
    let
      mkHostPortPairs =
        remoteBuildHosts:
        final.lib.mapAttrsToList (
          _: descriptor: with descriptor; {
            inherit hostName port;
          }
        ) remoteBuildHosts;
    in
    final.lib.concatMapStrings (
      pair:
      final.lib.optionalString (pair.port != null) ''

        Host ${pair.hostName}
        Port ${toString pair.port}
      ''
    ) (mkHostPortPairs remoteBuildHosts);

  # Given a set of remote build hosts of the hacknix remoteBuildHost
  # type, create an SSH known hosts config that can be used as a value
  # for `programs.ssh.knownHosts`.
  knownHosts =
    remoteBuildHosts:
    final.lib.mapAttrs'
      (
        host: descriptor:
        final.lib.nameValuePair host {
          hostNames = final.lib.singleton descriptor.hostName ++ descriptor.alternateHostNames;
          publicKey = descriptor.hostPublicKeyLiteral;
        }
      )
      (
        final.lib.filterAttrs (name: descriptor: descriptor.hostPublicKeyLiteral != null) remoteBuildHosts
      );

  # Given a set of remote build hosts of the hacknix remoteBuildHost
  # type, filter the set so that it only contains Macs.
  onlyMacs = final.lib.filterAttrs (
    _: v: final.lib.all (s: s == "x86_64-darwin" || s == "aarch64-darwin") v.systems
  );

  # The opposite of `onlyMacs`.
  allButMacs = final.lib.filterAttrs (
    _: v: final.lib.all (s: s != "x86_64-darwin" && s != "aarch64-darwin") v.systems
  );
in
{
  lib = (prev.lib or { }) // {
    hacknix = (prev.lib.hacknix or { }) // {
      path = ../..;

      inherit
        nixosSystem'
        nixosSystem
        amazonImage
        isoImage
        ;
      inherit darwinSystem' darwinSystem;
      inherit nixosGenerate' nixosGenerate;

      remote-build-host = (prev.lib.hacknix.remote-build-host or { }) // {
        inherit sshExtraConfig;
        inherit knownHosts;
        inherit onlyMacs allButMacs;
      };
    };
  };
}
