# Things that should generally be installed on physical hardware
# systems.

{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.hacknix.hardware.hwutils;
  enabled = cfg.enable;
in
{
  options.hacknix.hardware.hwutils = {
    enable = mkEnableOption ''
      packages that are useful for managing physical hardware.
    '';
  };

  config = mkIf enabled {
    environment.systemPackages = with pkgs; [
      flashrom
      lm_sensors
      pciutils
      usbutils
    ];
  };
}
