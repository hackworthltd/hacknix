# This is more or less the same as
# https://github.com/input-output-hk/ci-ops/blob/1de9d549321de5280db47b8eb318f535c072dbf7/modules/auto-gc.nix
#
# This file is copyright Input Output HK and is covered by the Apache
# License 2.0, a copy of which is included in this directory.

{ pkgs, config, lib, ... }:
let
  cfg = config.services.auto-gc;
  inherit (lib) types mkIf mkOption mkEnableOption;
in
{
  options = {
    services.auto-gc = {
      nixAutoGcEnable = mkEnableOption "automatic nix garbage collection.";

      nixAutoMaxFreedGB = mkOption {
        type = types.int;
        default = 110;
        description = "An maximum absolute amount to free up to on the auto GC";
      };

      nixAutoMinFreeGB = mkOption {
        type = types.int;
        default = 30;
        description = "The minimum amount to trigger an auto GC at";
      };

      nixHourlyGcEnable = mkEnableOption "an hourly nix garbage collection";

      nixHourlyMaxFreedGB = mkOption {
        type = types.int;
        default = 110;
        description = "The maximum absolute level to free up to on the /nix/store mount for the hourly timed GC";
      };

      nixHourlyMinFreeGB = mkOption {
        type = types.int;
        default = 20;
        description = "The minimum amount to trigger the /nix/store mount hourly timed GC at";
      };

      nixWeeklyGcFull = mkEnableOption "a weekly full nix garbage collection.";

      nixWeeklyGcOnCalendar = mkOption {
        type = types.str;
        default = "Sat *-*-* 20:00:00";
        description = "The default weekly day and time to perform a full GC, if enabled.  Uses systemd onCalendar format.";
      };
    };
  };

  config = {
    nix = mkIf cfg.nixAutoGcEnable {
      # This GC is run automatically by nix-build
      extraOptions = ''
        # Try to ensure between ${toString cfg.nixAutoMinFreeGB}G and ${toString cfg.nixAutoMaxFreedGB}G of free space by
        # automatically triggering a garbage collection if free
        # disk space drops below a certain level during a build.
        min-free = ${toString (cfg.nixAutoMinFreeGB * 1024 * 1024 * 1024)}
        max-free = ${toString (cfg.nixAutoMaxFreedGB * 1024 * 1024 * 1024)}
      '';
    };

    systemd.services.gc-hourly = mkIf cfg.nixHourlyGcEnable {
      script = ''
        free=$(${pkgs.coreutils}/bin/df --block-size=M --output=avail /nix/store | tail -n1 | sed s/M//)
        echo "Automatic GC: ''${free}M available"
        # Set the max absolute level to free to nixHourlyMaxFreedGB on the /nix/store mount
        if [ $free -lt ${toString (cfg.nixHourlyMinFreeGB * 1024)} ]; then
          ${config.nix.package}/bin/nix-collect-garbage --max-freed ${toString (cfg.nixHourlyMaxFreedGB * 1024 * 1024 * 1024)}
        fi
      '';
    };

    systemd.timers.gc-hourly = mkIf cfg.nixHourlyGcEnable {
      timerConfig = {
        Unit = "gc-hourly.service";
        OnCalendar = "*-*-* *:15:00";
      };
      wantedBy = [ "timers.target" ];
    };

    systemd.services.gc-weekly = mkIf cfg.nixWeeklyGcFull {
      script = "${config.nix.package}/bin/nix-collect-garbage";
    };

    systemd.timers.gc-weekly = mkIf cfg.nixWeeklyGcFull {
      timerConfig = {
        Unit = "gc-weekly.service";
        OnCalendar = cfg.nixWeeklyGcOnCalendar;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
