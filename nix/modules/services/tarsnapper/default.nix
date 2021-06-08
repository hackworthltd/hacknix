{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.tarsnapper;
  cacheDir = "/var/cache/tarsnap/tarsnapper";
  tarsnapConfigFile = ''
    keyfile ${cfg.keyfile}
    cachedir ${cacheDir}
    nodump
    print-stats
    checkpoint-bytes 1G
    exclude */tmp/*
    exclude *.core
  '';
  emailScript = pkgs.writeScript "tarsnapper-mail" ''
    #!${pkgs.stdenv.shell}

    ${cfg.email.sendmailPath} -t <<MAILEND
    To: $1
    From: tarsnapper <${cfg.email.from}>
    Subject: $2
    Content--Transfer-Encoding: 8bit
    Content-Type: text/plain; charset=UTF-8

    $(systemctl status --full tarsnapper.service)

    MAILEND
  '';
in
{
  options = {
    services.tarsnapper = {
      enable = mkEnableOption "periodic tarsnapper backups.";

      keyfile = mkOption {
        type = pkgs.lib.types.nonStorePath;
        example = "/var/lib/tarsnapper/tarsnap.key";
        description = ''
          A path to the tarsnap key which associates this machine with
          your tarsnap account, as a string literal. Create the key
          with <command>tarsnap-keygen</command>.
        '';
      };

      period = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "hourly";
        description = ''
          Create backups at this interval.

          The period format is described in
          <citerefentry><refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum></citerefentry>.
        '';
      };

      email = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            If true, send an email report containing the status of
            each tarsnapper backup job.

            This will only work if the host has a functioning
            <literal>sendmail</literal> configuration, or equivalent.
          '';
        };

        sendmailPath = mkOption {
          type = types.path;
          default = "/run/wrappers/bin/sendmail";
          description = ''
            The path to the <literal>sendmail</literal> executable you
            want to use. The default value is the NixOS default
            <literal>sendmail</literal>.
          '';
        };

        from = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "root@example.com";
          description = ''
            The email address from which backup notifications are
            sent, in the form <literal>username@domain</literal>.
          '';
        };

        toSuccess = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "root@example.com";
          description = ''
            The email address to which successful backup notifications are sent.
          '';
        };

        toFailure = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "root@example.com";
          description = ''
            The email address to which failed backup notifications are sent.
          '';
        };
      };

      config = mkOption {
        type = types.str;
        description = ''
          The tarsnapper config.
        '';
      };

    };
  };

  config = mkIf cfg.enable {

    systemd.services.tarsnapper = rec {
      description = "Tarsnapper backup";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      onFailure = if cfg.email.enable then [ "tarsnapper-failed.service" ] else [ ];

      path = with pkgs; [
        coreutils
        iputils
        nettools
        tarsnap
        tarsnapper
        util-linux
      ];

      script = ''
        set -e

        install -m 0700 -o root -g root -d ${cacheDir} > /dev/null 2>&1 || true

        TIMESTAMP=`date +\%Y\%m\%d-\%H\%M\%S`
        HOSTNAME=`hostname -f`
        tarsnapper -o configfile /etc/tarsnap/tarsnapper-tarsnap.conf --config /etc/tarsnap/tarsnapper.conf make
      '' + (
        optionalString cfg.email.enable ''
          ${emailScript} "${cfg.email.toSuccess}" "$HOSTNAME backup successful ($TIMESTAMP)"
        ''
      );

      serviceConfig = {
        Type = "oneshot";
        IOSchedulingClass = "idle";
        # Unfortunately, this does not work with sendmails that setuid (e.g., Postfix). See
        # https://github.com/NixOS/nixpkgs/issues/26611
        #NoNewPrivileges = "true";
        CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
      };
    };

    systemd.services.tarsnapper-failed = mkIf cfg.email.enable {
      description = "Runs when a tarsnapper backup fails";

      path = [ pkgs.nettools ];

      script = ''
        HOSTNAME=`hostname -f`
        ${emailScript} "${cfg.email.toFailure}" "$HOSTNAME backup FAILED"
      '';

      serviceConfig = {
        Type = "oneshot";
        User = "nobody";
        Group = "systemd-journal";
      };
    };

    # Note: the timer must be Persistent=true, so that systemd will start it even
    # if e.g. your laptop was asleep while the latest interval occurred.
    systemd.timers.tarsnapper = {
      timerConfig.OnCalendar = cfg.period;
      timerConfig.Persistent = "true";
      wantedBy = [ "timers.target" ];
    };

    # Put tarsnap, tarsnapper, and their config files in the system environment so that
    # an administrator can easily use them to check the status of backups, restore, etc.

    environment.etc = {
      "tarsnap/tarsnapper-tarsnap.conf" = { text = tarsnapConfigFile; };

      "tarsnap/tarsnapper.conf" = { text = cfg.config; };
    };

    environment.systemPackages = [ pkgs.tarsnap pkgs.tarsnapper ];

  };
}
