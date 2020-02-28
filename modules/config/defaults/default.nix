{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.hacknix.defaults;
  enabled = cfg.enable;

in
{

  options.hacknix.defaults = {
    enable = mkEnableOption
    ''
      all of the hacknix configuration defaults.

      These defaults will configure a NixOS server according to the
      good security practice. Note that some of the defaults may not
      be appropriate for an interactive desktop system.
    '';
  };

  config = mkIf enabled {

    hacknix.defaults = {

      acme.enable = true;
      environment.enable = true;
      networking.enable = true;
      nginx.enable = true;
      nix.enable = true;
      security.enable = true;
      ssh.enable = true;
      sudo.enable = true;
      system.enable = true;
      tmux.enable = true;
      users.enable = true;

    };

  };

}
