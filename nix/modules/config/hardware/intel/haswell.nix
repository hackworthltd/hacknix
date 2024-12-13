# Configuration common to Intel Haswell systems.

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.hacknix.hardware.intel.haswell;
  enabled = cfg.enable;
in
{
  options.hacknix.hardware.intel.haswell = {
    enable = mkEnableOption "a Intel Haswell hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.intel.common.enable = true;
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
  };
}
