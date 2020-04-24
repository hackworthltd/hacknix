{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.hacknix.defaults.tmux;
  enabled = cfg.enable;

in {
  options.hacknix.defaults.tmux = {
    enable = mkEnableOption "the hacknix tmux configuration defaults.";
  };

  config = mkIf enabled {
    programs.tmux = {
      enable = true;
      shortcut = "z";
      terminal = "screen-256color";
    };
  };
}
