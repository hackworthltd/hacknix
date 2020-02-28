# Safer sudo defaults.

{ config, lib, ... }:

with lib;

let

  cfg = config.hacknix.defaults.sudo;
  enabled = cfg.enable;

in
{
  options.hacknix.defaults.sudo = {
    enable = mkEnableOption "the hacknix sudo configuration defaults.";
  };

  config = mkIf enabled {

    # If we don't reset TZ, services that are started in a sudo shell
    # might use the user's original timezone settings, rather than the
    # system's. Note that we must remove TZ from both env_check, and
    # then explicitly "unset" it in sudo.env, to make sure it's not
    # set in the sudo environment.
    security.sudo.extraConfig =
      ''
        Defaults        !lecture,tty_tickets,!fqdn,always_set_home,env_reset,env_file="/etc/sudo.env"
        Defaults        env_check -= "TZ"
        Defaults        env_keep -= "TZ TMOUT HISTFILE"
      '';

    # Don't save shell history and time out idle shells.
    environment.etc."sudo.env".text =
      ''
        export TMOUT=120
        export HISTFILE=
        export TZ=
      '';
    environment.etc."sudo.env".mode = "0640";

  };
}
