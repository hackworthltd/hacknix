{ config, pkgs, lib, ... }:
let
  cfg = config.services.avahi-reflector;
  enabled = cfg.enable;

  fwRulesPerInterface = interfaces:
    (
      map
        (
          interface: {
            protocol = "udp";
            dest.port = 5353;
            inherit interface;
          }
        )
        interfaces
    );
in
{
  options.services.avahi-reflector = {
    enable = lib.mkEnableOption ''
      a Bounjour repeater, via Avahi's reflector functionality.
    '';

    interfaces = lib.mkOption {
      type = lib.types.listOf pkgs.lib.types.nonEmptyStr;
      example = [ "eno2" ];
      description = ''
        A list of interface device names on which the Avahi reflector
        will listen, and across which Avahi will reflect Bonjour
        packets. All other interfaces will be ignored.
      '';
    };
  };

  config = lib.mkIf enabled {
    services.avahi = {
      enable = true;
      inherit (cfg) interfaces;
      ipv4 = true;
      ipv6 = true;
      openFirewall = false;
      reflector = true;
      nssmdns = true;
    };

    # These firewall rules are probably not strictly necessary, as
    # Avahi should handle it, but it's an easy defense-in-depth
    # strategy, so we do it anyway.
    networking.firewall.accept = fwRulesPerInterface cfg.interfaces;
    networking.firewall.accept6 = fwRulesPerInterface cfg.interfaces;
  };
}
