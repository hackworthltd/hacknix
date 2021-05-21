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
    # No config currently.
  };
}
