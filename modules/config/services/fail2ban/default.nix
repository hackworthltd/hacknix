{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.hacknix.services.fail2ban;
  fail2ban-enabled = config.services.fail2ban.enable;

  ignoreip = concatStringsSep " " ([ "127.0.0.0/8" "::1/128" ] ++ cfg.whitelist);

  note = ''

    Note: this option will only take effect if the
    <literal>fail2ban</literal> service is enabled. Setting this
    option does not automatically enable <literal>fail2ban</literal>
  '';

in
{
  options.hacknix.services.fail2ban = {

    whitelist = mkOption {
      type = types.listOf (types.either pkgs.lib.types.ipv4 pkgs.lib.types.ipv6);
      default = [];
      example = [ "192.0.2.0/24" "198.51.100.1" "2001:db8::/64" "2001:db8:1::1" ];
      description = ''
        A list of IP addresses that are whitelisted for all fail2ban
        jails; i.e., these adresses will never be banned by fail2ban.

        Note that the loopback address ranges (both IPv4 and IPv6) are
        always whitelisted and should not be listed here.
        ${note}
      '';
    };

    bantime = mkOption {
      type = types.ints.positive;
      default = 600;
      example = 86400;
      description = ''
        The default fail2ban <literal>bandtime</literal>; i.e., how
        long an offending IP address will be banned.
        ${note}
      '';
    };

    findtime = mkOption {
      type = types.ints.positive;
      default = 600;
      example = 86400;
      description = ''
        The default fail2ban <literal>findtime</literal>.
        ${note}
      '';
    };

    maxretry = mkOption {
      type = types.ints.positive;
      default = 3;
      example = 5;
      description = ''
        The default fail2ban <literal>maxretry</literal> settings;
        i.e., how many times an attempt can be made from an IP address
        before it is banned.
        ${note}
      '';
    };

  };

  config = mkIf fail2ban-enabled {

    hacknix.assertions.moduleHashes."services/security/fail2ban.nix" =
      "a7e5f9c5718ec19ecb556ba1e72c76f6c110f66d183919708e6ba65d8d11f78d";

    services.fail2ban.jails.DEFAULT = mkForce ''
      ignoreip = ${ignoreip}
      bantime = ${toString cfg.bantime}
      findtime = ${toString cfg.findtime}
      maxretry = ${toString cfg.maxretry}
      backend = systemd
      enabled = true
    '';

  };

}
