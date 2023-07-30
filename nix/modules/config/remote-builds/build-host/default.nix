{ config, lib, pkgs, ... }:
let
  cfg = config.hacknix.build-host;
  enabled = cfg.enable;

  defaultPrivateKey = "${cfg.sshKeyDir}/remote-builder";
  extraMachinesPath = "nix/extra-machines";
  mkBuildMachines = remoteBuildHosts:
    lib.mapAttrsToList
      (
        host: descriptor:
          with descriptor; {
            inherit hostName systems maxJobs speedFactor mandatoryFeatures
              supportedFeatures
              ;
            sshUser = sshUserName;
            sshKey = defaultPrivateKey;
          }
      )
      remoteBuildHosts;
  buildMachines = mkBuildMachines cfg.buildMachines;
  extraBuildMachines = mkBuildMachines cfg.extraBuildMachines;
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

      This service will create an SSH keypair. The generated private
      key will be used to connect to remote builders. The public half
      of the key pair can be found in the
      <literal>sshKeyDir</literal>, so that you can find it and
      install it on the remote builder(s).
    '';

    sshKeyDir = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "/etc/nix/remote-build-keys";
      example = "/var/lib/remote-build-keys";
      description = ''
        A directory where the SSH private keys for the remote build
        host users are stored on the target machine.
      '';
    };

    createSshKey = lib.mkOption {
      type = pkgs.lib.types.bool;
      default = true;
      description = ''
        Whether to automatically create an SSH keypair for the remote
        build host user.

        If this option is set to <literal>false</literal>, then you
        must provide a private SSH key in the
        <option>sshKeyDir</option>, in a file named
        <literal>remote-builder</literal>, and you must set the proper
        private key file permissions and ownership.
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

        Note that this option is ignored if
        <option>createSshKey</option> is set to
        <literal>false</literal>.
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

    programs.ssh.knownHosts =
      pkgs.lib.ssh.wellKnownHosts
      // (pkgs.lib.hacknix.remote-build-host.knownHosts cfg.buildMachines)
      // (pkgs.lib.hacknix.remote-build-host.knownHosts cfg.extraBuildMachines);
    programs.ssh.extraConfig = (pkgs.lib.hacknix.remote-build-host.sshExtraConfig cfg.buildMachines)
      + (pkgs.lib.hacknix.remote-build-host.sshExtraConfig cfg.extraBuildMachines);

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
        )
        extraBuildMachines;
    };

    systemd.tmpfiles.rules =
      if cfg.createSshKey then [
        "d ${cfg.sshKeyDir}            0755 root root -  -"
      ] else [ ];

    systemd.services.create-remote-builder-key = {
      enable = cfg.createSshKey;
      description = "Create a default remote builder SSH keypair";
      wantedBy = [ "multi-user.target" ];
      script = ''
        if [ ! -e ${defaultPrivateKey} ]; then
          echo "Creating default remote builder private key..."
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ${defaultPrivateKey} -q -N ""
        fi
        chown ${cfg.sshKeyFileOwner}:root ${defaultPrivateKey}
        chown ${cfg.sshKeyFileOwner}:root ${defaultPrivateKey}.pub
        chmod 0400 ${defaultPrivateKey}
        chmod 0444 ${defaultPrivateKey}.pub
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
