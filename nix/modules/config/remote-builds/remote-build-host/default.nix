{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hacknix.remote-build-host;
  enabled = cfg.enable;
  authorizedKeys = map (key: ''
    command="nix-store --serve --write" ${key}
  '') ((map builtins.readFile cfg.user.sshPublicKeyFiles) ++ cfg.user.sshPublicKeys);
in
{

  options.hacknix.remote-build-host = {
    enable = lib.mkEnableOption ''
      remote builds, i.e., configure the host to performs
      Nix builds for other hosts.

      Enabling this option will create a user dedicated to remote
      builds. This user will be added to
      <literal>nix.settings.trusted-users</literal>.
    '';

    user = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = "remote-builder";
        readOnly = true;
        description = ''
          The name of the user that's created by this module to run
          remote builds.

          This is a read-only attribute and is provided so that other
          modules can refer to it.
        '';
      };

      sshPublicKeyFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        example = lib.literalExpression [ ./remote-builder.pub ];
        description = ''
          The public SSH key files used to identify the remote builder
          user. The corresponding private keys should be installed on
          the build host that is using this remote build host.
        '';
      };

      sshPublicKeys = lib.mkOption {
        type = lib.types.listOf pkgs.lib.types.nonEmptyStr;
        default = [ ];
        example = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyxBrYrpql9WJ4m+1Hex+OT5Bxd1HPZZmUwa6MIvZ+E aarch64-build-box (20171217)"
        ];
        description = ''
          The public SSH keys (as a list of string literals) used to
          identify the remote builder user. The corresponding private
          keys should be installed on the build host that is using
          this remote build host.
        '';
      };
    };

  };

  config = lib.mkIf enabled {
    hacknix.defaults.ssh.enable = true;

    programs.ssh.knownHosts = pkgs.lib.ssh.wellKnownHosts;

    nix.settings.trusted-users = [ cfg.user.name ];

    users.users."${cfg.user.name}" = {
      useDefaultShell = true;
      description = "Nix remote builder";
      openssh.authorizedKeys.keys = authorizedKeys;
      isSystemUser = true;
      group = "${cfg.user.name}";
    };
    users.groups."${cfg.user.name}" = { };

    # Useful utilities.
    environment.systemPackages = with pkgs; [
      htop
      glances
    ];
  };

}
