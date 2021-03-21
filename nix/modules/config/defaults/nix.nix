{ config, pkgs, lib, ... }:

let
  cfg = config.hacknix.defaults.nix;
in
{
  options.hacknix.defaults.nix = {
    enable = lib.mkEnableOption ''
      the hacknix Nix configuration defaults.

      At the moment, all this option does is enable Nix flakes support
      for the system Nix version.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Enable flakes support.
    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
  };
}
