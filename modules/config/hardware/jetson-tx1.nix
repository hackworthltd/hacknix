# Configuration common to Jetson TX1 hosts.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.jetson-tx1;
  enabled = cfg.enable;

in {
  options.hacknix.hardware.jetson-tx1 = {
    enable =
      mkEnableOption "NVIDIA Jetson TX1-specific hardware configuration.";
  };

  config = mkIf enabled {
    nixpkgs.localSystem.system = "aarch64-linux";

    hardware.enableAllFirmware = true;

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    boot.kernelPackages = pkgs.linuxPackages_latest;

    boot.initrd.availableKernelModules = [ "ahci_tegra" "nvme" ];

    # Manual doesn't currently evaluate on ARM
    services.nixosManual.enable = false;
  };
}
