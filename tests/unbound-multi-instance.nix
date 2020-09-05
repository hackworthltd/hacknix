{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  ipv6_prefix = "fd00:1234:5678::/64";
  adblock_ipv4 = "192.168.1.251";
  noblock_ipv4 = "192.168.1.252";
  adblock_ipv6 = "fd00:1234:5678::1";
  noblock_ipv6 = "fd00:1234:5678::2";
  imports = pkgs.lib.hacknix.modules;

in
makeTestPython rec {

  name = "unbound-multi-instance";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {

    nsd = { config, ... }: {
      nixpkgs.localSystem.system = system;
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.250";
          prefixLength = 24;
        }
      ];
      networking.interfaces.eth1.ipv6.addresses = [
        {
          address = "fd00:1234:5678::ffff";
          prefixLength = 64;
        }
      ];
      networking.firewall.allowedUDPPorts = [ 53 ];
      networking.firewall.allowedTCPPorts = [ 53 ];
      services.nsd.enable = true;
      services.nsd.interfaces = [ "192.168.1.250" ];
      services.nsd.zones."example.com.".data = ''
        @ SOA ns.example.com noc.example.com 666 7200 3600 1209600 3600
        ipv4 A 1.2.3.4
        ipv6 AAAA abcd::eeff
      '';
      services.nsd.zones."doubleclick.net.".data = ''
        @ SOA ns.doubleclick.net noc.doubleclick.net 666 7200 3600 1209600 3600
        ad A 13.13.13.13
        ad AAAA dead::beef
      '';
    };

    server = { pkgs, config, ... }: {
      nixpkgs.localSystem.system = system;
      inherit imports;
      networking.useDHCP = false;
      networking.firewall.allowedUDPPorts = [ 53 ];
      networking.firewall.allowedTCPPorts = [ 53 ];
      services.unbound-multi-instance.instances = {
        adblock = {
          enableRootTrustAnchor = false; # required for testing.
          allowedAccess = [ "192.168.1.2/32" ipv6_prefix ];
          listenAddresses = [ adblock_ipv4 adblock_ipv6 ];
          forwardAddresses = [ "192.168.1.250" ];
          extraConfig =
            builtins.readFile "${pkgs.badhosts-unified}/unbound.conf";
        };

        noblock = {
          enableRootTrustAnchor = false; # required for testing.
          allowedAccess = [ "192.168.1.2/32" ipv6_prefix ];
          listenAddresses = [ noblock_ipv4 noblock_ipv6 ];
          forwardAddresses = [ "192.168.1.250" ];
        };
      };
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.1";
          prefixLength = 24;
        }
      ];
      networking.interfaces.eth1.ipv6.addresses = [
        {
          address = "fd00:1234:5678::1000";
          prefixLength = 64;
        }
      ];
      boot.kernelModules = [ "dummy" ];
      networking.interfaces.dummy0.ipv4.addresses = [
        {
          address = adblock_ipv4;
          prefixLength = 32;
        }
        {
          address = noblock_ipv4;
          prefixLength = 32;
        }
      ];
      networking.interfaces.dummy0.ipv6.addresses = [
        {
          address = adblock_ipv6;
          prefixLength = 128;
        }
        {
          address = noblock_ipv6;
          prefixLength = 128;
        }
      ];
    };

    client = { config, ... }: {
      nixpkgs.localSystem.system = system;
      networking.useDHCP = false;
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.2";
          prefixLength = 24;
        }
      ];
      networking.interfaces.eth1.ipv6.addresses = [
        {
          address = "fd00:1234:5678::2000";
          prefixLength = 64;
        }
      ];
    };

    badclient = { config, ... }: {
      nixpkgs.localSystem.system = system;
      networking.useDHCP = false;
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.3";
          prefixLength = 24;
        }
      ];
      networking.interfaces.eth1.ipv6.addresses = [
        {
          address = "fd00:1234:5678::3000";
          prefixLength = 64;
        }
      ];
    };

  };

  testScript = { nodes, ... }: ''
    start_all()

    server.wait_for_unit("unbound-adblock.service")
    server.wait_for_unit("unbound-noblock.service")
    nsd.wait_for_unit("nsd.service")
    client.wait_for_unit("multi-user.target")
    badclient.wait_for_unit("multi-user.target")

    with subtest("Doubleclick"):
        assert "status: NXDOMAIN" in client.succeed(
            "${nodes.client.pkgs.dnsutils}/bin/dig @${adblock_ipv4} A ad.doubleclick.net"
        )
        assert "status: NXDOMAIN" in client.succeed(
            "${nodes.client.pkgs.dnsutils}/bin/dig @${adblock_ipv4} AAAA ad.doubleclick.net"
        )
        assert "13.13.13.13" in client.succeed(
            "${nodes.client.pkgs.dnsutils}/bin/dig @${noblock_ipv4} A ad.doubleclick.net"
        )
        assert "dead::beef" in client.succeed(
            "${nodes.client.pkgs.dnsutils}/bin/dig @${noblock_ipv4} AAAA ad.doubleclick.net"
        )

    with subtest("Forwarding"):
        assert "1.2.3.4" in client.succeed(
            "${nodes.client.pkgs.dnsutils}/bin/dig @${adblock_ipv4} A ipv4.example.com +short"
        )
        assert "1.2.3.4" in client.succeed(
            "${nodes.client.pkgs.dnsutils}/bin/dig @${noblock_ipv4} A ipv4.example.com +short"
        )

    with subtest("Bad client"):
        badclient.fail(
            "${nodes.badclient.pkgs.dnsutils}/bin/dig @${adblock_ipv4} A ad.doubleclick.net +time=2"
        )
        badclient.fail(
            "${nodes.badclient.pkgs.dnsutils}/bin/dig @${noblock_ipv4} A ad.doubleclick.net +time=2"
        )

    with subtest("Stop the service"):
        server.stop_job("unbound-adblock.service")
        server.stop_job("unbound-noblock.service")
  '';
}
