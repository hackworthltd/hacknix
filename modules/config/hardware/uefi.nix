# Configuration common to UEFI systems.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.uefi;
  mbr_enabled = config.hacknix.hardware.mbr.enable;
  enabled = cfg.enable;

in
{
  options.hacknix.hardware.uefi = {
    enable = mkEnableOption "the systemd-boot EFI boot loader.";
  };

  config = mkIf enabled {
    assertions = [
      { assertion = ! mbr_enabled;
        message = "Both 'hacknix.hardware.mbr' and 'hacknix.hardware.uefi' cannot be enabled";
      }
    ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
