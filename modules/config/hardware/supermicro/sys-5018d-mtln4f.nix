# SuperMicro 5018D-MTLN4F system config. Note that this server
# supports multiple processor microarchitectures, so you must select
# the processor features separately.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.supermicro.sys-5018d-mtln4f;
  enabled = cfg.enable;

in
{
  options.hacknix.hardware.supermicro.sys-5018d-mtln4f = {
    enable = mkEnableOption ''
      a Supermicro 5018D-MTLN4F hardware configuration.

      Note that, unlike some other Supermicro configurations, this
      system supports multiple processor microarchitectures, so you
      must enable the processor platform that corresponds to your
      hardware separately.
    '';
  };

  config = mkIf enabled {
    boot.kernelModules = [ "coretemp" "jc42" "nct6775" ];
  };
}
