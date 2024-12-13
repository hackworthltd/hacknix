{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hacknix.defaults.nix;
in
{
  options.hacknix.defaults.nix = {
    enable = lib.mkEnableOption ''
      the hacknix Nix configuration defaults.

      At the moment, this does nothing.
    '';
  };

  config = lib.mkIf cfg.enable { };
}
