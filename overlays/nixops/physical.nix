{ system ? "x86_64-linux"
, config ? {
    allowUnfree = true;
  }
, localLib ? import ../../nix/default.nix { inherit system config; }
, pkgs ? localLib.pkgs
}:

{
  machine1 = { ... }: {
    config = {
      nixpkgs.config.allowUnfree = true;
      hacknix.hardware = {
        hwutils.enable = true;
        mbr.enable = true;
        apu2.apu3c4.enable = true;
      };
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
      boot.loader.grub.devices = [ "/dev/sda" ];
    };
  };
}
