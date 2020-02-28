# SuperMicro 5017A-EF system config.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.supermicro.sys-5017a-ef;
  enabled = cfg.enable;

in
{
  options.hacknix.hardware.supermicro.sys-5017a-ef = {
    enable = mkEnableOption "a Supermicro 5017A-EF hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.intel.centerton.enable = true;
    boot.kernelModules = [ "coretemp" "jc42" "w83795" "i2c_isch" ];
  };
}
