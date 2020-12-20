# Configuration common to Intel Sandy Bridge physical hardware systems.

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hacknix.hardware.intel.sandy-bridge;
  enabled = cfg.enable;
in
{
  options.hacknix.hardware.intel.sandy-bridge = {
    enable = mkEnableOption "Intel Sandy Bridge hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.intel.common.enable = true;
    boot.initrd.availableKernelModules =
      [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  };
}
