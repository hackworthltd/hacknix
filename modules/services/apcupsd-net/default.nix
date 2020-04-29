# # Run apcupsd in a PowerChute Network Shutdown configuration; i.e.,
## with a network-enabled APC Smart-UPS.
##
## A similar configuration can be created with the NixOS built-in
## apcupsd module, but that module has the drawback that the
## PowerChute Network Shutdown credentials (basically just a plaintext
## password) will be written to the Nix store. This module prevents
## that from happening by using the hacknix keychain to deploy the
## configuration containing the secret to the host.
##
## Another drawback of the NixOS apcupsd module is that it configures
## the service to run a "killpower" job to power down the UPS as the
## host is shutting down. In a network-enabled configuration, where
## the UPS is potentially powering multiple hosts all with different
## shutdown criteria and priorities, you almost never want a single
## host to shut down the UPS!

{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.apcupsd-net;
  apcupsdCfg = config.services.apcupsd;

  keyName = "apcupsd-net";
  stateDir = "/var/lib/apcupsd-net";

  configFile = config.hacknix.keychain.keys."${keyName}";

  configText = ''
    ## apcupsd.conf v1.1 ##
    # apcupsd complains if the first line is not like above.
    UPSNAME ${cfg.ups.name}
    UPSCABLE ether
    UPSTYPE pcnet
    DEVICE ${cfg.ups.ip}:${cfg.shutdownCredentials}:${toString cfg.localPort}

    ONBATTERYDELAY 6
    BATTERYLEVEL ${toString cfg.batteryLevel}
    MINUTES -1
    TIMEOUT 0
    ANNOY 300
    ANNOYDELAY 60
    NOLOGON disable
    KILLDELAY 0

    NETSERVER on
    NISIP 127.0.0.1
    NISPORT 3551
    SCRIPTDIR ${toString scriptDir}
  '';

  # List of events from "man apccontrol"
  eventList = [
    "annoyme"
    "battattach"
    "battdetach"
    "changeme"
    "commfailure"
    "commok"
    "doreboot"
    "doshutdown"
    "emergency"
    "failing"
    "killpower"
    "loadlimit"
    "mainsback"
    "onbattery"
    "offbattery"
    "powerout"
    "remotedown"
    "runlimit"
    "timeout"
    "startselftest"
    "endselftest"
  ];

  shellCmdsForEventScript = eventname: commands: ''
    echo "#!${pkgs.runtimeShell}" > "$out/${eventname}"
    echo '${commands}' >> "$out/${eventname}"
    chmod a+x "$out/${eventname}"
  '';

  eventToShellCmds = event:
    if builtins.hasAttr event cfg.hooks then
      (shellCmdsForEventScript event (builtins.getAttr event cfg.hooks))
    else
      "";

  scriptDir = pkgs.runCommand "apcupsd-scriptdir" {} (
    ''
      mkdir "$out"
      # Copy SCRIPTDIR from apcupsd package
      cp -r ${pkgs.apcupsd}/etc/apcupsd/* "$out"/
      # Make the files writeable (nix will unset the write bits afterwards)
      chmod u+w "$out"/*
      # Remove the sample event notification scripts, because they don't work
      # anyways (they try to send mail to "root" with the "mail" command)
      (cd "$out" && rm changeme commok commfailure onbattery offbattery)
      # Remove the sample apcupsd.conf file (we're generating our own)
      rm "$out/apcupsd.conf"
      # Set the SCRIPTDIR= line in apccontrol to the dir we're creating now
      sed -i -e "s|^SCRIPTDIR=.*|SCRIPTDIR=$out|" "$out/apccontrol"
    '' + concatStringsSep "\n" (map eventToShellCmds eventList)

  );
in
{

  ###### interface

  options = {

    services.apcupsd-net = {

      enable = mkEnableOption ''
        the APC UPS daemon and configure it for use with a
        network-enabled APC SmartUPS unit.

        Note that this configuration only works with network-enabled
        SmartUPSes. For USB-connected UPSes, use the
        <literal>apcupsd</literal> module.
      '';

      ups = {

        name = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "ups1";
          description = ''
            A short name for the UPS. Do not use the UPS FQDN here as
            <literal>apcupsd</literal> cannot deal with special
            characters (e.g., ".") in the name.
          '';
        };

        ip = mkOption {
          type = pkgs.lib.types.ipv4NoCIDR;
          example = "192.168.1.30";
          description = ''
            The IPv4 address of the UPS.
          '';
        };

      };

      localPort = mkOption {
        type = pkgs.lib.types.port;
        default = 3052;
        example = 3000;
        description = ''
          The <em>local</em> UDP port to which the UPS will connect
          to send status updates and alerts to the host.

          Note that this port must be connectable from the UPS's IPv4
          address. If you have enabled the host's firewall, you must
          ensure that the appropriate firewall rules are in place;
          this module will not do that for you.
        '';
      };

      batteryLevel = mkOption {
        type = types.ints.between 0 100;
        example = 50;
        default = 15;
        description = ''
          Shut down this host when the UPS battery level reaches this
          percentage of total capacity.
        '';
      };

      shutdownCredentials = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "foobar";
        description = ''
          A shared secret between the UPS and the host which serves to
          authenticate the UPS to the host.

          Note that this module will ensure that this secret is not
          written to the Nix store. It will be uploaded to the host
          upon deployment.
        '';
      };

      hooks = mkOption {
        default = {};
        example = {
          doshutdown =
            "# shell commands to notify that the computer is shutting down";
        };
        type = types.attrsOf types.str;
        description = ''
          Each attribute in this option names an apcupsd event and the string
          value it contains will be executed in a shell, in response to that
          event (prior to the default action). See "man apccontrol" for the
          list of events and what they represent.

          A hook script can stop apccontrol from doing its default action by
          exiting with value 99. Do not do this unless you know what you're
          doing.
        '';
      };

    };

  };

  ###### implementation

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = let
          hooknames = builtins.attrNames cfg.hooks;
        in all (x: elem x eventList) hooknames;
        message = ''
          One (or more) attribute names in services.apcupsd.hooks are invalid.
          Current attribute names: ${toString (builtins.attrNames cfg.hooks)}
          Valid attribute names  : ${toString eventList}
        '';
      }

      {
        assertion = !apcupsdCfg.enable;
        message = ''
          Only one of `services.apcupsd` and `services.apcupsd-net` can be enabled at one time.
        '';
      }
    ];

    # Keep track of changes in the upstream module.
    hacknix.assertions.moduleHashes."services/monitoring/apcupsd.nix" =
      "049210f3395709b20e41ce492fff6ceecc4145922a3d96f0010f42a1d5a71d33";

    hacknix.keychain.keys."${keyName}" = {
      destDir = stateDir;
      text = configText;
    };

    # Give users access to the "apcaccess" tool
    environment.systemPackages = [ pkgs.apcupsd ];

    # NOTE 1: apcupsd runs as root because it needs permission to run
    # "shutdown"
    #
    # NOTE 2: When apcupsd calls "wall", it prints an error because stdout is
    # not connected to a tty (it is connected to the journal):
    #   wall: cannot get tty name: Inappropriate ioctl for device
    # The message still gets through.
    systemd.services.apcupsd = rec {
      description = "APC UPS network client daemon";
      wantedBy = [ "multi-user.target" ];
      wants = [ "${keyName}-key.service" ];
      after = wants;
      preStart = "mkdir -p /run/apcupsd/";
      serviceConfig = {
        ExecStart = "${pkgs.apcupsd}/bin/apcupsd -b -f ${configFile.path} -d1";
        # TODO: When apcupsd has initiated a shutdown, systemd always ends up
        # waiting for it to stop ("A stop job is running for UPS daemon"). This
        # is weird, because in the journal one can clearly see that apcupsd has
        # received the SIGTERM signal and has already quit (or so it seems).
        # This reduces the wait time from 90 seconds (default) to just 5. Then
        # systemd kills it with SIGKILL.
        TimeoutStopSec = 5;
      };
      unitConfig.Documentation = "man:apcupsd(8)";
    };

  };

  meta.maintainers = lib.maintainers.dhess;

}
