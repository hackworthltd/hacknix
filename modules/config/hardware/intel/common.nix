# Configuration common to modern Intel physical hardware systems.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.intel.common;
  enabled = cfg.enable;

in
{
  options.hacknix.hardware.intel.common = {
    enable = mkEnableOption "a Intel hardware configuration common to modern Intel platforms.";
  };

  config = mkIf enabled {
    nixpkgs.localSystem.system = "x86_64-linux";

    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    hardware.cpu.intel.updateMicrocode = true;

    powerManagement.cpuFreqGovernor = "powersave";

    # irqbalance is still recommended for general-purpose computing.
    # Enable it by default.
    # ref: https://serverfault.com/questions/513807/is-there-still-a-use-for-irqbalance-on-modern-hardware
    services.irqbalance.enable = true;

    hardware.enableAllFirmware = true;
  };
}
