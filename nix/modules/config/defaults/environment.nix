{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.hacknix.defaults.environment;
  enabled = cfg.enable;
in
{
  options.hacknix.defaults.environment = {
    enable =
      mkEnableOption "the hacknix shell environment configuration defaults.";
  };

  config = mkIf enabled {
    environment.systemPackages = with pkgs; [ emacs-nox git wget ];

    # Disable HISTFILE globally.
    environment.interactiveShellInit = ''
      unset HISTFILE
    '';

    programs.bash.enableCompletion = true;
  };
}
