# Configuration common to Intel Coffee Lake physical hardware systems.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.intel.coffee-lake;
  enabled = cfg.enable;

in
{
  options.hacknix.hardware.intel.coffee-lake = {
    enable = mkEnableOption "a Intel Coffee Lake hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.intel.common.enable = true;
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" ];
  };
}
