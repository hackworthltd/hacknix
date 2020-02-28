{ config
, pkgs
, lib
, ...
}:

let

  cfg = config.hacknix.providers.vultr.cloud;
  enabled = cfg.enable;

in
{
  options.hacknix.providers.vultr.cloud = {
    enable = lib.mkEnableOption "configuration defaults for Vultr Cloud Compute VPSes.";
  };

  config = lib.mkIf enabled {
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.devices = [ "/dev/vda" ];
    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    nixpkgs.localSystem.system = "x86_64-linux";
  };
}
