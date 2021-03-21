{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.hacknix-nix-darwin.defaults.nix;
in
{
  options.hacknix-nix-darwin.defaults.nix = {
    enable = lib.mkEnableOption "the hacknix Nix configuration defaults.";
  };

  config = lib.mkIf cfg.enable {
    # Enable Nix flakes support. Most macOS machines are interactive
    # machines, not remote builders, so this is a good default.
    nix.package = pkgs.nixUnstable;
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
