# Configuration common to Intel Centerton (Atom Processor S Series)
# hardware systems.

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hacknix.hardware.intel.centerton;
  enabled = cfg.enable;
in
{
  options.hacknix.hardware.intel.centerton = {
    enable = mkEnableOption "a Intel Centerton hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.intel.common.enable = true;
    boot.initrd.availableKernelModules =
      [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  };
}
