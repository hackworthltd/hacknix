{ config, lib, pkgs, ... }:

let

  cfg = config.hacknix.auto-gc;
  enabled = cfg.enable;

in
{

  options.hacknix.auto-gc = {
    enable = lib.mkEnableOption ''
      automatic Nix store garbage colleciton. This is useful on
      remote build hosts.
    '';
  };

  config = lib.mkIf enabled {

    # From
    # https://github.com/NixOS/nixos-org-configurations/blob/340bd2eef8b5adee5b8712788e414c7a8b3e6e2d/delft/build-machines-common.nix
    # and
    # https://github.com/input-output-hk/iohk-ops/blob/master/modules/hydra-slave.nix
    nix.gc = {
      automatic = true;
      dates = "*:15:00";
      options = ''--max-freed "$((32 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    };
    systemd.timers.nix-gc.timerConfig.RandomizedDelaySec = "1800";

  };

}
