{ config
, lib
, ...
}:

with lib;

let

  cfg = config.hacknix.defaults.acme;
  enabled = cfg.enable;

in
{
  options.hacknix.defaults.acme = {
    enable = mkEnableOption "the hacknix ACME module configuration defaults.";
  };

  config = mkIf enabled {
    security.acme.acceptTerms = true;
  };
}
