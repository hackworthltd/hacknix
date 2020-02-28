# SuperMicro 5018D-FN4T system.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.supermicro.sys-5018d-fn4t;
  enabled = cfg.enable;

in
{
  options.hacknix.hardware.supermicro.sys-5018d-fn4t = {
    enable = mkEnableOption "a Supermicro 5018D-FN4T hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.intel.broadwell-de.enable = true;
    boot.kernelModules = [ "coretemp" "jc42" "nct6775" ];
  };
}
