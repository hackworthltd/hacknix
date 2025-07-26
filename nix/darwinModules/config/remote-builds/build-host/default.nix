{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.hacknix-nix-darwin.build-host;

  defaultPrivateKey = "${cfg.sshKeyDir}/remote-builder";
  mkBuildMachines =
    remoteBuildHosts:
    lib.mapAttrsToList (
      host: descriptor: with descriptor; {
        inherit
          hostName
          systems
          maxJobs
          speedFactor
          mandatoryFeatures
          supportedFeatures
          ;
        sshUser = sshUserName;
        sshKey = defaultPrivateKey;
        protocol = "ssh-ng";
      }
    ) remoteBuildHosts;
  sshConfig = pkgs.writeText "ssh_config" (
    pkgs.lib.hacknix.remote-build-host.sshExtraConfig cfg.buildMachines
  );
in
{
  options.hacknix-nix-darwin.build-host = {
    enable = lib.mkEnableOption ''
      build-host support for macOS, i.e., a macOS host from which nixpkgs
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
      default = "/var/lib/remote-build-keys";
      example = "/etc/nix/remote-build-keys";
      description = ''
        A directory where the files containing the SSH private keys
        for the remote build host users are stored.

        These key files must be deployed via another method. This
        module only configures the target host's nix-daemon to look in
        this location for the key files.
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
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.buildMachines != { };
        message = "`hacknix-nix-darwin.build-host` is enabled, but `hacknix-nix-darwin.build-host.buildMachines` is empty";
      }
    ];

    nix.extraOptions = ''
      keep-derivations = true
      keep-outputs = true
    '';

    nix.distributedBuilds = true;
    nix.buildMachines = mkBuildMachines cfg.buildMachines;
    programs.ssh.knownHosts =
      pkgs.lib.ssh.wellKnownHosts // (pkgs.lib.hacknix.remote-build-host.knownHosts cfg.buildMachines);

    system.activationScripts.postActivation.text = ''
      mkdir -p ~root/.ssh
      ${pkgs.coreutils}/bin/chmod 0700 ~root/.ssh
      cp -f ${sshConfig} ~root/.ssh/config
      ${pkgs.coreutils}/bin/chown -R root:wheel ~root/.ssh/config
      ${pkgs.coreutils}/bin/chmod 0400 ~root/.ssh/config
    ''
    + lib.optionalString cfg.createSshKey ''
      printf "Creating remote builder ssh key directory and setting permissions... "
      install -m 0755 -o root -g wheel -d ${cfg.sshKeyDir}
      echo "ok"

      if [ ! -e ${defaultPrivateKey} ]; then
        printf "Creating default remote builder private key... "
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ${defaultPrivateKey} -q -N ""
        echo "ok"
      fi

      printf "Setting permissions on default remote builder keypair... "
      ${pkgs.coreutils}/bin/chown root:wheel ${defaultPrivateKey}
      ${pkgs.coreutils}/bin/chown root:wheel ${defaultPrivateKey}.pub
      ${pkgs.coreutils}/bin/chmod 0400 ${defaultPrivateKey}
      ${pkgs.coreutils}/bin/chmod 0444 ${defaultPrivateKey}.pub
      echo "ok"
    '';
  };
}
