# Configuration common to MBR/GRUB systems.

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hacknix.hardware.mbr;
  uefi_enabled = config.hacknix.hardware.uefi.enable;
  enabled = cfg.enable;
in
{
  options.hacknix.hardware.mbr = {
    enable = mkEnableOption "GRUB for MBR-based boot.";
  };

  config = mkIf enabled {
    assertions = [
      {
        assertion = !uefi_enabled;
        message =
          "Both 'hacknix.hardware.mbr' and 'hacknix.hardware.uefi' cannot be enabled";
      }
    ];

    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
  };
}
