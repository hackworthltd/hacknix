{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.hacknix.defaults.nix;
  enabled = cfg.enable;
in
{
  options.hacknix.defaults.nix = {
    enable = mkEnableOption "the hacknix Nix configuration defaults.";
  };

  config = mkIf enabled {

    nixpkgs.config.allowUnfree = true;

    # Most of the following config is thanks to Graham Christensen,
    # from:
    # https://github.com/grahamc/network/blob/1d73f673b05a7f976d82ae0e0e61a65d045b3704/modules/standard/default.nix#L56

    nix = {
      useSandbox = true;
      nixPath = [
        (
          let
            cfg = pkgs.writeText "configuration.nix" ''
              assert builtins.trace "This server is managed by NixOps; do not run `nixos-rebuild` here." false;
              {}
            '';
          in
          "nixos-config=${cfg}"
        )

        # Copy the channel version from the deploy host to the target
        "nixpkgs=/run/current-system/nixpkgs"
      ];
    };

    system.extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
    environment.etc.host-nix-channel.source = pkgs.path;

  };

}
