{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
  index = pkgs.writeText "index.html" ''
    Not really HTML.
  '';

  extraHosts = ''
    192.168.1.1 server
    fd00:1234:0:5678::1000 server
    192.168.2.1 server_vlan2
    fd00:1234:0:5679::1000 server_vlan2
    192.168.1.2 client1
    fd00:1234:0:5678::2000 client1
    192.168.1.3 client2
    fd00:1234:0:5678::3000 client2
    192.168.2.2 client3
    fd00:1234:0:5679::2000 client3

    # A virtual IP.
    10.0.0.8 virtual_server
    fd00:1234:0:567a::1000 virtual_server
  '';

  makeAllowedIPsTest = name:
    makeTest rec {

      inherit name;

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {

        server = { config, ... }: {
          nixpkgs.localSystem.system = system;
          imports = pkgs.lib.hacknix.modules;
          networking.useDHCP = false;
          networking.extraHosts = extraHosts;
          networking.firewall.enable = true;
          networking.firewall.rejectPackets = true;
          networking.firewall.accept = [

            # Only client1 can connect on port 80.

            {
              protocol = "tcp";
              dest.port = 80;
              src.ip = "192.168.1.2/32";
            }

            # Any host on the network can connect to 8080:8081, but only
            # when the source port is in the range 800:801.

            {
              protocol = "tcp";
              dest.port = "8080:8081";
              src.port = "800:801";
              src.ip = "192.168.0.0/16";
            }

            ## Only packets entering on eth2 can connect to port 8088.

            {
              protocol = "tcp";
              dest.port = 8088;
              interface = "eth2";
              src.ip = "192.168.0.0/16";
            }

            ## Only packets bound for the virtual IP can connect to port
            ## 8089.

            {
              protocol = "tcp";
              dest.port = 8089;
              dest.ip = "10.0.0.8/32";
            }
          ];
          networking.firewall.accept6 = [

            # Only client1 can connect on port 80.

            {
              protocol = "tcp";
              dest.port = 80;
              src.ip = "fd00:1234:0:5678::2000/128";
            }

            # Any host on the network can connect to 8080:8081, but only
            # when the source port is in the range 800:801.

            {
              protocol = "tcp";
              dest.port = "8080:8081";
              src.port = "800:801";
              src.ip = "fd00:1234:0:5600::/56";
            }

            ## Only packets entering on eth2 can connect to port 8088.

            {
              protocol = "tcp";
              dest.port = 8088;
              interface = "eth2";
              src.ip = "fd00:1234:0:5600::/56";
            }

            ## Only packets bound for the virtual IP can connect to port
            ## 8089.

            {
              protocol = "tcp";
              dest.port = 8089;
              dest.ip = "fd00:1234:0:567a::1000/128";
            }
          ];
          services.nginx = {
            enable = true;
            virtualHosts."server" = {
              default = true;
              listen = [
                {
                  addr = "0.0.0.0";
                  port = 80;
                }
                {
                  addr = "0.0.0.0";
                  port = 8080;
                }
                {
                  addr = "0.0.0.0";
                  port = 8081;
                }
                {
                  addr = "0.0.0.0";
                  port = 8088;
                }
                {
                  addr = "0.0.0.0";
                  port = 8089;
                }
                {
                  addr = "[::]";
                  port = 80;
                }
                {
                  addr = "[::]";
                  port = 8080;
                }
                {
                  addr = "[::]";
                  port = 8081;
                }
                {
                  addr = "[::]";
                  port = 8088;
                }
                {
                  addr = "[::]";
                  port = 8089;
                }
              ];
              locations."/".root = pkgs.runCommand "docroot" {} ''
                mkdir -p "$out/"
                cp "${index}" "$out/index.html"
              '';
            };
          };

          # server lives on both networks.
          virtualisation.vlans = [ 1 2 ];
          networking.interfaces.eth1 = {
            ipv4.addresses = pkgs.lib.mkOverride 0 [
              {
                address = "192.168.1.1";
                prefixLength = 24;
              }
            ];
            ipv6.addresses = pkgs.lib.mkOverride 0 [
              {
                address = "fd00:1234:0:5678::1000";
                prefixLength = 64;
              }
            ];
          };
          networking.interfaces.eth2 = {
            ipv4.addresses = pkgs.lib.mkOverride 0 [
              {
                address = "192.168.2.1";
                prefixLength = 24;
              }
            ];
            ipv6.addresses = pkgs.lib.mkOverride 0 [
              {
                address = "fd00:1234:0:5679::1000";
                prefixLength = 64;
              }
            ];
          };
          boot.kernelModules = [ "dummy" ];
          networking.interfaces.dummy0.ipv4.addresses = [
            {
              address = "10.0.0.8";
              prefixLength = 32;
            }
          ];
          networking.interfaces.dummy0.ipv6.addresses = [
            {
              address = "fd00:1234:0:567a::1000";
              prefixLength = 128;
            }
          ];
        };

        client1 = { config, ... }: {
          nixpkgs.localSystem.system = system;
          networking.useDHCP = false;
          networking.extraHosts = extraHosts;
          networking.defaultGateway = "192.168.1.1";
          networking.defaultGateway6 = "fd00:1234:0:5678::1000";
          networking.interfaces.eth1.ipv4.addresses = pkgs.lib.mkOverride 0 [
            {
              address = "192.168.1.2";
              prefixLength = 24;
            }
          ];
          networking.interfaces.eth1.ipv6.addresses = pkgs.lib.mkOverride 0 [
            {
              address = "fd00:1234:0:5678::2000";
              prefixLength = 64;
            }
          ];
        };

        client2 = { config, ... }: {
          nixpkgs.localSystem.system = system;
          networking.useDHCP = false;
          networking.defaultGateway = "192.168.1.1";
          networking.defaultGateway6 = "fd00:1234:0:5678::1000";
          networking.extraHosts = extraHosts;
          networking.interfaces.eth1.ipv4.addresses = pkgs.lib.mkOverride 0 [
            {
              address = "192.168.1.3";
              prefixLength = 24;
            }
          ];
          networking.interfaces.eth1.ipv6.addresses = pkgs.lib.mkOverride 0 [
            {
              address = "fd00:1234:0:5678::3000";
              prefixLength = 64;
            }
          ];
        };

        # client3 lives on vlan 2.

        client3 = { config, ... }: {
          nixpkgs.localSystem.system = system;
          networking.useDHCP = false;
          networking.defaultGateway = "192.168.2.1";
          networking.defaultGateway6 = "fd00:1234:0:5679::1000";
          networking.extraHosts = extraHosts;
          virtualisation.vlans = [ 2 ];
          networking.interfaces.eth1.ipv4.addresses = pkgs.lib.mkOverride 0 [
            {
              address = "192.168.2.2";
              prefixLength = 24;
            }
          ];
          networking.interfaces.eth1.ipv6.addresses = pkgs.lib.mkOverride 0 [
            {
              address = "fd00:1234:0:5679::2000";
              prefixLength = 64;
            }
          ];
        };

      };

      testScript = { nodes, ... }: ''
        startAll;

        $server->waitForUnit("nginx.service");
        $client1->waitForUnit("multi-user.target");
        $client2->waitForUnit("multi-user.target");
        $client3->waitForUnit("multi-user.target");

        # Make sure we have IPv6 connectivity and there isn't an issue
        # with the network setup in the test.

        sub waitForAddress {
            my ($machine, $iface, $scope) = @_;
            $machine->waitUntilSucceeds("[ `ip -o -6 addr show dev $iface scope $scope | grep -v tentative | wc -l` -eq 1 ]");
            my $ip = (split /[ \/]+/, $machine->succeed("ip -o -6 addr show dev $iface scope $scope"))[3];
            $machine->log("$scope address on $iface is $ip");
            return $ip;
        }

        waitForAddress $client1, "eth1", "global";
        waitForAddress $client2, "eth1", "global";
        waitForAddress $client3, "eth1", "global";
        waitForAddress $server, "eth1", "global";

        $server->succeed("ping -c 1 192.168.1.2 >&2");
        $server->succeed("ping -c 1 fd00:1234:0:5678::2000 >&2");
        $server->succeed("ping -c 1 192.168.1.3 >&2");
        $server->succeed("ping -c 1 fd00:1234:0:5678::3000 >&2");
        $server->succeed("ping -c 1 192.168.2.2 >&2");
        $server->succeed("ping -c 1 fd00:1234:0:5679::2000 >&2");

        $client1->succeed("ping -c 1 192.168.1.1 >&2");
        $client1->succeed("ping -c 1 10.0.0.8 >&2");
        $client1->succeed("ping -c 1 fd00:1234:0:5678::1000 >&2");
        $client1->succeed("ping -c 1 fd00:1234:0:567a::1000 >&2");
        $client2->succeed("ping -c 1 192.168.1.1 >&2");
        $client2->succeed("ping -c 1 10.0.0.8 >&2");
        $client2->succeed("ping -c 1 fd00:1234:0:5678::1000 >&2");
        $client2->succeed("ping -c 1 fd00:1234:0:567a::1000 >&2");
        $client3->succeed("ping -c 1 192.168.2.1 >&2");
        $client3->succeed("ping -c 1 10.0.0.8 >&2");
        $client3->succeed("ping -c 1 fd00:1234:0:5679::1000 >&2");
        $client3->succeed("ping -c 1 fd00:1234:0:567a::1000 >&2");

        subtest "remote-connections", sub {
          $client1->succeed("${pkgs.curl}/bin/curl --output - -4 http://server:80");
          $client1->succeed("${pkgs.curl}/bin/curl --output - -6 http://server:80");
          $client1->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8080");
          $client1->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8081");
          $client1->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8081");
          $client1->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8081");
          $client1->succeed("${pkgs.curl}/bin/curl --output - --local-port 800 -4 http://server:8080");
          $client1->succeed("${pkgs.curl}/bin/curl --output - --local-port 801 -6 http://server:8081");
          $client1->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8088");
          $client1->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8088");
          $client1->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8089");
          $client1->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8089");
          $client1->succeed("${pkgs.curl}/bin/curl --output - -4 http://virtual_server:8089");
          $client1->succeed("${pkgs.curl}/bin/curl --output - -6 http://virtual_server:8089");

          $client2->fail("${pkgs.curl}/bin/curl --output - -4 http://server:80");
          $client2->fail("${pkgs.curl}/bin/curl --output - -6 http://server:80");
          $client2->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8080");
          $client2->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8081");
          $client2->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8080");
          $client2->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8081");
          $client2->succeed("${pkgs.curl}/bin/curl --output - --local-port 800 -4 http://server:8080");
          $client2->succeed("${pkgs.curl}/bin/curl --output - --local-port 801 -6 http://server:8081");
          $client2->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8088");
          $client2->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8088");
          $client2->fail("${pkgs.curl}/bin/curl --output - -4 http://server:8089");
          $client2->fail("${pkgs.curl}/bin/curl --output - -6 http://server:8089");
          $client2->succeed("${pkgs.curl}/bin/curl --output - -4 http://virtual_server:8089");
          $client2->succeed("${pkgs.curl}/bin/curl --output - -6 http://virtual_server:8089");

          $client3->fail("${pkgs.curl}/bin/curl --output - -4 http://server_vlan2:80");
          $client3->fail("${pkgs.curl}/bin/curl --output - -6 http://server_vlan2:80");
          $client3->fail("${pkgs.curl}/bin/curl --output - -4 http://server_vlan2:8080");
          $client3->fail("${pkgs.curl}/bin/curl --output - -4 http://server_vlan2:8081");
          $client3->fail("${pkgs.curl}/bin/curl --output - -6 http://server_vlan2:8080");
          $client3->fail("${pkgs.curl}/bin/curl --output - -6 http://server_vlan2:8081");
          $client3->succeed("${pkgs.curl}/bin/curl --output - --local-port 800 -4 http://server_vlan2:8080");
          $client3->succeed("${pkgs.curl}/bin/curl --output - --local-port 801 -6 http://server_vlan2:8081");
          $client3->succeed("${pkgs.curl}/bin/curl --output - -4 http://server:8088");
          $client3->succeed("${pkgs.curl}/bin/curl --output - -6 http://server:8088");
          $client3->fail("${pkgs.curl}/bin/curl --output - -4 http://server_vlan2:8089");
          $client3->fail("${pkgs.curl}/bin/curl --output - -6 http://server_vlan2:8089");
          $client3->succeed("${pkgs.curl}/bin/curl --output - -4 http://virtual_server:8089");
          $client3->succeed("${pkgs.curl}/bin/curl --output - -6 http://virtual_server:8089");
        };
      '';
    };
in
{ accept = makeAllowedIPsTest "accept"; }
