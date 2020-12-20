{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.hacknix.defaults.ssh;
  enabled = cfg.enable;
in
{
  options.hacknix.defaults.ssh = {
    enable = mkEnableOption "the hacknix SSH configuration defaults.";
  };

  config = mkIf enabled {

    services.openssh.enable = true;
    services.openssh.passwordAuthentication = false;
    services.openssh.permitRootLogin = lib.mkForce "prohibit-password";

    # Prevent users from installing their own authorized_keys.

    services.openssh.authorizedKeysFiles =
      pkgs.lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];

    ## Additional sshd_config
    #
    # Note: we use mkOrder 999 to give the user a chance to override
    # it in mkFooter.
    #
    # We do the following:
    #
    # - Disable SSH agent forwarding. Yes, the sshd_config(5) man page
    #   points out that this doesn't prevent users from installing
    #   their own forwaders. This isn't meant to prevent that. It's
    #   meant to prevent accidents; e.g., where the user is in the
    #   habit of adding a "-A" flag to ssh, or perhaps they enabled
    #   agent forwarding in their .ssh/config and forgot about it.
    #
    # - Support more reliable GPG forwarding with
    #   StreamLocalBindUnlink.
    services.openssh.extraConfig = lib.mkOrder 999 ''
      AllowAgentForwarding no
      StreamLocalBindUnlink yes
    '';
  };
}
