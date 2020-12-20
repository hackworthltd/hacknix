{ testingPython, ... }:
with testingPython;
let
  makeNetsniffNgTest = name: machineAttrs:
    makeTest {

      name = "netsniff-ng-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {

        sniffer = { pkgs, config, ... }:
          {
            services.netsniff-ng.instances.test = {
              inputInterface = "eth0";
              outputBaseDirectory = "/var/log/netsniff-ng";
            };

          } // machineAttrs;

        pinger = { pkgs, config, ... }: { };

      };

      testScript = { nodes, ... }:
        let
          pingerpkgs = nodes.pinger.pkgs;
        in
        ''
          import re

          start_all()
          sniffer.wait_for_unit("netsniff-ng@test.service")
          pinger.wait_for_unit("network.target")

          with subtest("Runs as non-root"):
              # Note: it takes a bit of time for netsniff-ng to configure
              # the interface before it drops privileges.
              sniffer.succeed("sleep 5")
              output = sniffer.succeed("ps -u netsniff-ng")
              assert re.search(
                  "[0-9]+.* netsniff-ng",
                  output,
                  flags=re.DOTALL,
              )


          # This test should go last, as it stops the service on sniffer.
          with subtest("Traffic captured"):
              # This isn't a very robust test, but I'm having trouble
              # getting any traffic to show up in the pcap files on sniffer.
              # It may have something to do with the way NixOS's test
              # harness configures VirtualBox networking. For now, just make
              # sure that when we stop the netsniff-ng service that it
              # reports packets have been captured.

              pinger.succeed("ping -c 3 sniffer >&2")

              # Make sure at least that the pcap files have been created.
              sniffer.succeed("[ -f /var/log/netsniff-ng/test/test-*.pcap ]")

              # What we're looking for here is a non-zero number of packets
              # incoming and passed; and that the counts are equal.

              sniffer.succeed("systemctl stop netsniff-ng\@test.service")
              output = sniffer.succeed("journalctl -xn 10 -a -u netsniff-ng\@test.service")
              assert re.search(
                  "[1-9][0-9]*  packets incoming",
                  output,
                  flags=re.DOTALL,
              )
              assert re.search(
                  "[1-9][0-9]*  packets passed filter",
                  output,
                  flags=re.DOTALL,
              )
              assert "0  packets failed filter" in output
        '';

    };
in
makeNetsniffNgTest "default" { }
