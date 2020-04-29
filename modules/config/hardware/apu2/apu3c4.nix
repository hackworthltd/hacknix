# PC Engines apu3c4 system.

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hacknix.hardware.apu2.apu3c4;
  enabled = cfg.enable;
in
{
  options.hacknix.hardware.apu2.apu3c4 = {
    enable = mkEnableOption "PC Engines apu3c4 hardware configuration.";
  };

  config = mkIf enabled {
    hacknix.hardware.amd.jaguar.enable = true;

    # Serial console.
    boot.kernelParams = [ "console=ttyS0,115200n8" ];
    boot.loader.grub.extraConfig =
      "serial --unit=0 --speed=115200 ; terminal_input serial console ; terminal_output serial console";
  };
}
