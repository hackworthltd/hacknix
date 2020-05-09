{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
  makeNetsniffNgTest = name: machineAttrs:
    makeTest {

      name = "netsniff-ng-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {

        sniffer = { config, ... }:
          {
            nixpkgs.localSystem.system = system;
            imports = pkgs.lib.hacknix.modules;

            services.netsniff-ng.instances.test = {
              inputInterface = "eth0";
              outputBaseDirectory = "/var/log/netsniff-ng";
            };

          } // machineAttrs;

        pinger = { config, ... }: { nixpkgs.localSystem.system = system; };

      };

      testScript = { nodes, ... }:
        let
          pingerpkgs = nodes.pinger.pkgs;
        in
        ''
          startAll;
          $sniffer->waitForUnit("netsniff-ng\@test.service");
          $pinger->waitForUnit("network.target");

          subtest "running-as-non-root", sub {

            # Note: it takes a bit of time for netsniff-ng to configure
            # the interface before it drops privileges.
            $sniffer->succeed("sleep 5");
            $sniffer->succeed("ps -u netsniff-ng") =~ /[0-9]+.* netsniff-ng/ or die "netsniff-ng is not running as the expected user";
          };

          # This test should go last, as it stops the service on sniffer.
          subtest "traffic-captured", sub {

            # This isn't a very robust test, but I'm having trouble
            # getting any traffic to show up in the pcap files on sniffer.
            # It may have something to do with the way NixOS's test
            # harness configures VirtualBox networking. For now, just make
            # sure that when we stop the netsniff-ng service that it
            # reports packets have been captured.

            $pinger->succeed("ping -c 3 sniffer >&2");

            # Make sure at least that the pcap files have been created.
            $sniffer->succeed("[ -f /var/log/netsniff-ng/test/test-*.pcap ]");

            # What we're looking for here is a non-zero number of packets
            # incoming and passed; and that the counts are equal.

            $sniffer->succeed("systemctl stop netsniff-ng\@test.service");
            my $out = $sniffer->succeed("journalctl -xn 10 -a -u netsniff-ng\@test.service");
            $out =~ /[1-9][0-9]*  packets incoming/ or die "no packets captured?";
            $out =~ /[1-9][0-9]*  packets passed filter/ or die "packets were filtered?";
            $out =~ /0  packets failed filter/ or die "one or more packets were dropped?";
          };
        '';

    };
in
{

  defaultTest = makeNetsniffNgTest "default" { };

}
