{ config, lib, ... }:

with lib;
let
  cfg = config.hacknix.defaults.system;
  enabled = cfg.enable;
in
{
  options.hacknix.defaults.system = {
    enable = mkEnableOption "the hacknix system configuration defaults.";
  };

  config = mkIf enabled {
    i18n.defaultLocale = "en_US.UTF-8";
    services.logrotate.enable = true;
    time.timeZone = "Etc/UTC";
  };
}
