{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
  ipv6_prefix = "fd00:1234:5678::/64";
  adblock_ipv4 = "192.168.1.251";
  noblock_ipv4 = "192.168.1.252";
  adblock_ipv6 = "fd00:1234:5678::1";
  noblock_ipv6 = "fd00:1234:5678::2";
in
makeTest rec {

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

    server = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules;
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
    startAll;

    $server->waitForUnit("unbound-adblock.service");
    $server->waitForUnit("unbound-noblock.service");
    $nsd->waitForUnit("nsd.service");
    $client->waitForUnit("multi-user.target");
    $badclient->waitForUnit("multi-user.target");

    # Make sure we have IPv6 connectivity and there isn't an issue
    # with the network setup in the test.

    sub waitForAddress {
        my ($machine, $iface, $scope) = @_;
        $machine->waitUntilSucceeds("[ `ip -o -6 addr show dev $iface scope $scope | grep -v tentative | wc -l` -eq 1 ]");
        my $ip = (split /[ \/]+/, $machine->succeed("ip -o -6 addr show dev $iface scope $scope"))[3];
        $machine->log("$scope address on $iface is $ip");
        return $ip;
    }

    waitForAddress $client, "eth1", "global";
    waitForAddress $badclient, "eth1", "global";
    waitForAddress $server, "eth1", "global";
    waitForAddress $nsd, "eth1", "global";

    $server->succeed("ping -c 1 fd00:1234:5678::2000 >&2");
    $server->succeed("ping -c 1 fd00:1234:5678::3000 >&2");
    $server->succeed("ping -c 1 fd00:1234:5678::ffff >&2");
    $client->succeed("ping -c 1 fd00:1234:5678::1000 >&2");
    $badclient->succeed("ping -c 1 fd00:1234:5678::1000 >&2");

    sub testDoubleclickBlocked {
      my ($machine, $dnsip, $extraArg) = @_;
      my $ipv4 = $machine->succeed("${pkgs.dnsutils}/bin/dig \@$dnsip $extraArg A ad.doubleclick.net");
      $ipv4 =~ /status: NXDOMAIN/ or die "ad.doubleclick.net does not return NXDOMAIN";
      my $ipv6 = $machine->succeed("${pkgs.dnsutils}/bin/dig \@$dnsip $extraArg AAAA ad.doubleclick.net");
      $ipv6 =~ /status: NXDOMAIN/ or die "ad.doubleclick.net does not return NXDOMAIN";
    }

    sub testDoubleclick {
      my ($machine, $dnsip, $extraArg) = @_;
      my $ipv4 = $machine->succeed("${pkgs.dnsutils}/bin/dig \@$dnsip $extraArg A ad.doubleclick.net +short");
      $ipv4 =~ /^13\.13\.13\.13$/ or die "ad.doubleclick.net does not resolve to 13.13.13.13";
      my $ipv6 = $machine->succeed("${pkgs.dnsutils}/bin/dig \@$dnsip $extraArg AAAA ad.doubleclick.net +short");
      $ipv6 =~ /^dead::beef$/ or die "ad.doubleclick.net does not resolve to dead::beef";
    }

    subtest "doubleclick", sub {
      testDoubleclickBlocked $client, "${adblock_ipv4}", "";
      #testDoubleclickBlocked $client, "${adblock_ipv6}", "-6";
      testDoubleclick $client, "${noblock_ipv4}", "";
      #testDoubleclick $client, "${noblock_ipv6}", "-6";
    };

    subtest "forwarding", sub {
      my $ip1 = $client->succeed("${pkgs.dnsutils}/bin/dig \@${adblock_ipv4} A ipv4.example.com +short");
      $ip1 =~ /^1\.2\.3\.4$/ or die "ipv4.example.com does not resolve to 1.2.3.4 from adblock instance";
      my $ip2 = $client->succeed("${pkgs.dnsutils}/bin/dig \@${noblock_ipv4} A ipv4.example.com +short");
      $ip2 =~ /^1\.2\.3\.4$/ or die "ipv4.example.com does not resolve to 1.2.3.4 from noblock instance";
    };

    subtest "badclient", sub {
      $badclient->fail("${pkgs.dnsutils}/bin/dig \@${adblock_ipv4} A ad.doubleclick.net +time=2");
      $badclient->fail("${pkgs.dnsutils}/bin/dig \@${noblock_ipv4} A ad.doubleclick.net +time=2");
      #$badclient->fail("${pkgs.dnsutils}/bin/dig \@${adblock_ipv6} A ad.doubleclick.net +time=2");
      #$badclient->fail("${pkgs.dnsutils}/bin/dig \@${noblock_ipv6} A ad.doubleclick.net +time=2");
    };

    subtest "check-stop", sub {
      $server->stopJob("unbound-adblock.service");
      $server->stopJob("unbound-noblock.service");
    };

  '';
}
