{ config, lib, ... }:

with lib;
let
  cfg = config.hacknix.defaults.security;
  enabled = cfg.enable;
in
{
  options.hacknix.defaults.security = {
    enable = mkEnableOption "the hacknix security configuration defaults.";
  };

  config = mkIf enabled {

    boot.tmp.cleanOnBoot = true;
    boot.kernel.sysctl = { "kernel.unprivileged_bpf_disabled" = 1; };

  };
}
