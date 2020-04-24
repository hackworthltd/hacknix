# Configuration common to Intel Kaby Lake physical hardware systems.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.intel.kaby-lake;
  enabled = cfg.enable;

in {
  options.hacknix.hardware.intel.kaby-lake = {
    enable = mkEnableOption "a Intel Kaby Lake hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.intel.common.enable = true;
    boot.initrd.availableKernelModules =
      [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  };
}
