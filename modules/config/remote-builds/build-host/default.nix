{ config, lib, pkgs, ... }:
let
  cfg = config.hacknix.build-host;
  enabled = cfg.enable;
  extraMachinesPath = "nix/extra-machines";
  sshKeyName = host: user: "${user}_at_${host}";
  mkBuildMachines = remoteBuildHosts:
    lib.mapAttrsToList
      (
        host: descriptor:
          with descriptor; {
            inherit hostName systems maxJobs speedFactor mandatoryFeatures
              supportedFeatures
              ;
            sshUser = "ssh://${sshUserName}";
            sshKey =
              let
                keyname = sshKeyName host sshUserName;
              in
              config.hacknix.keychain.keys.${keyname}.path;
          }
      ) remoteBuildHosts;
  buildMachines = mkBuildMachines cfg.buildMachines;
  extraBuildMachines = mkBuildMachines cfg.extraBuildMachines;
  mkHostPortPairs = remoteBuildHosts:
    lib.mapAttrsToList
      (_: descriptor: with descriptor; { inherit hostName port; })
      remoteBuildHosts;
  sshExtraConfig = remoteBuildHosts:
    lib.concatMapStrings
      (
        pair:
        lib.optionalString (pair.port != null) ''

        Host ${pair.hostName}
        Port ${toString pair.port}
      ''
      ) (mkHostPortPairs remoteBuildHosts);
  knownHosts = remoteBuildHosts:
    lib.mapAttrs'
      (
        host: descriptor:
          lib.nameValuePair descriptor.hostName {
            hostNames = lib.singleton descriptor.hostName
              ++ descriptor.alternateHostNames;
            publicKey = descriptor.hostPublicKeyLiteral;
          }
      ) remoteBuildHosts;
  genKeys = remoteBuildHosts:
    lib.mapAttrs'
      (
        host: descriptor:
          let
            keyName = sshKeyName host descriptor.sshUserName;
          in
          lib.nameValuePair keyName {
            destDir = cfg.sshKeyDir;
            text = descriptor.sshKeyLiteral;
            user = cfg.sshKeyFileOwner;
            group = "root";
            permissions = "0400";
          }
      ) remoteBuildHosts;
in
{

  options.hacknix.build-host = {
    enable = lib.mkEnableOption ''
      this host as a build host, i.e., a machine from which Nixpkgs
      builds can be performed using remote builders.

      This module will configure this host to use the given remote
      build hosts as remote builders. This includes setting the
      <option>nix.buildMachines</option>, as well as all of the user
      and host keys needed by SSH to log into those remote builders
      without needing any manual set-up. (For example, most Nix guides
      to remote builds tell you to manually SSH to the remote build
      host once before enabling remote builds, in order to get SSH to
      accept the remote build host's host key; but if you configure
      this module properly, that will not be necessary.)
    '';

    sshKeyDir = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "/etc/nix";
      example = "/var/lib/remote-build-keys";
      description = ''
        A directory where the SSH private keys for the remote build
        host users are stored.

        These keys will be deployed securely to this directory on the
        build host; i.e., they will not be copied to the Nix store.
      '';
    };

    sshKeyFileOwner = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "root";
      example = "hydra-queue-runner";
      description = ''
        The name of the user who will own the SSH private keys for
        remote build host users, giving that user read-only access to
        the key. No other user or group will be able to read the keys,
        and no user or group will be permitted to write them.

        If you are running a Hydra server on this build host, and you
        plan to use the same set of build hosts and SSH keys for the
        Hydra server as the ones you are defining in this module, then
        you'll want to set this option to
        <literal>hydra-queue-runner</literal>; otherwise, the default
        value (<literal>root</literal>) is usually the one you want.
      '';
    };

    buildMachines = lib.mkOption {
      default = { };
      description = ''
        An attrset containing remote build host descriptors.

        The machines in this attrset will be added to
        <literal>/etc/nix/machines</literal>, so that they're used by
        <literal>nix-daemon</literal> for remote builds that are
        initiated from this host.
      '';
      type = lib.types.attrsOf pkgs.lib.types.remoteBuildHost;
    };

    extraBuildMachines = lib.mkOption {
      default = { };
      description = ''
        An attrset containing remote build host descriptors.

        The machines in this attrset will be added to a file named by
        the <option>extraBuildMachinesFile</option> option.

        Note that these machines will <em>not</em> automatically be
        used by <literal>nix-daemon</literal>, but you can use these
        machine definitions for other programs that expect the same
        file format (e.g., Hydra).

        This functionaliy is useful when you want to use
        different/additional build machines for a local Hydra than
        <literal>nix-daemon</literal> uses.
      '';
      type = lib.types.attrsOf pkgs.lib.types.remoteBuildHost;
    };

    extraBuildMachinesFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/${extraMachinesPath}";
      readOnly = true;
      description = ''
        The name of the file in which the remote build hosts defined
        by <option>extraBuildMachines</option> will be stored.

        This attribute is read-only, and is provided so that other
        modules can safely determine the path to the file containing
        these definitions.
      '';
    };

  };

  config = lib.mkIf enabled {

    assertions = [
      {
        assertion = cfg.buildMachines != { };
        message =
          "`hacknix.build-host` is enabled, but `hacknix.build-host.buildMachines` is empty";
      }
    ];

    nix.distributedBuilds = true;
    nix.buildMachines = buildMachines;

    programs.ssh.knownHosts = (knownHosts cfg.buildMachines)
      // (knownHosts cfg.extraBuildMachines);
    programs.ssh.extraConfig = (sshExtraConfig cfg.buildMachines)
      + (sshExtraConfig cfg.extraBuildMachines);

    hacknix.keychain.keys = (genKeys cfg.buildMachines)
      // (genKeys cfg.extraBuildMachines);

    users.users."${cfg.sshKeyFileOwner}".extraGroups = if cfg.sshKeyFileOwner == "root" then [ ] else [ "keys" ];

    # We need to generate our own machines file for the extra
    # machines. Unfortunately, this functionality is not exported from
    # Nixpkgs, so this code is taken from nixpkgs
    # (nixos/modules/services/misc/nix-daemon.nix):

    environment.etc."${extraMachinesPath}" = {
      text = lib.concatMapStrings
        (
          machine:
          "${ if machine ? sshUser then "${machine.sshUser}@" else ""
            }${machine.hostName} "
          + machine.system or (lib.concatStringsSep "," machine.systems)
          + " ${machine.sshKey or "-"} ${toString machine.maxJobs or 1} "
          + toString (machine.speedFactor or 1) + " " + lib.concatStringsSep ","
            (machine.mandatoryFeatures or [ ] ++ machine.supportedFeatures or [ ])
          + " " + lib.concatStringsSep "," machine.mandatoryFeatures or [ ]
          + "\n"
        ) extraBuildMachines;
    };

  };

}
