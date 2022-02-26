{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.hacknix.defaults;
  enabled = cfg.enable;
in
{

  options.hacknix.defaults = {
    enable = mkEnableOption ''
      all of the hacknix configuration defaults.
    '';
  };

  config = mkIf enabled {
    nixpkgs.config.allowUnfree = true;

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

    # Most of the following config is thanks to Graham Christensen,
    # from:
    # https://github.com/grahamc/network/blob/1d73f673b05a7f976d82ae0e0e61a65d045b3704/modules/standard/default.nix#L56

    nix = {
      settings.sandbox = true;
      nixPath = [
        (
          let
            cfg = pkgs.writeText "configuration.nix" ''
              assert builtins.trace "This server is managed remotely; do not run `nixos-rebuild` here." false;
              {}
            '';
          in
          "nixos-config=${cfg}"
        )
        "nixpkgs=/run/current-system/nixpkgs"
      ];
    };

    system.extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
  };
}
