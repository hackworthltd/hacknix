{ config, lib, ... }:

with lib;

let

  cfg = config.hacknix.defaults.users;
  enabled = cfg.enable;

in
{
  options.hacknix.defaults.users = {
    enable = mkEnableOption "the hacknix user configuration defaults.";
  };

  config = mkIf enabled {

    users.mutableUsers = false;

  };
}
