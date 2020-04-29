{ config, pkgs, lib, ... }:
let
  cfg = config.hacknix.providers.linode;
  enabled = cfg.enable;
in
{
  options.hacknix.providers.linode = {
    enable = lib.mkEnableOption "configuration defaults for Linode VPSes.";
  };

  config = lib.mkIf enabled {
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.timeout = 10;

    # Needed for Linodes.
    boot.loader.grub.device = "nodev";

    boot.initrd.availableKernelModules = [ "ata_piix" "sd_mod" ];
    boot.kernelModules = [];
    boot.extraModulePackages = [];

    # Linode LISH support.
    boot.kernelParams = [ "console=ttyS0,19200n8" ];
    boot.loader.grub.extraConfig = ''
      serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
      terminal_input serial;
      terminal_output serial
    '';

    networking.usePredictableInterfaceNames = false;
    nixpkgs.localSystem.system = "x86_64-linux";
  };
}
