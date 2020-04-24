{ system ? "x86_64-linux", pkgs, makeTest, ... }:

let

  makeTsoffTest = name: machineAttrs:
    makeTest {
      name = "tsoff-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };
      machine = { config, ... }:
        {
          nixpkgs.localSystem.system = system;
          imports = pkgs.lib.hacknix.modules;
        } // machineAttrs;
      testScript = { nodes, ... }: ''
        $machine->waitForUnit("network.target");

        subtest "disables-offloads", sub {
          $machine->succeed("${pkgs.tsoff}/bin/tsoff -v eth0");
          my $out = $machine->succeed("${pkgs.ethtool}/bin/ethtool --show-offload eth0");
          chomp $out;
          for my $line (split /\n/, $out) {
            chomp $line;
            # This will ignore features that are "[fixed]", which is
            # what we want.
            if ($line =~ /^\s*([a-z0-9_-]+):\s+on$/) {
              die "Offload feature '$1' not disabled";
            }
          }
        };

        subtest "is-idempotent", sub {
          # Should just silently succeed.
          $machine->succeed("${pkgs.tsoff}/bin/tsoff -v eth0");
        };
      '';
    };

in { defaultTest = makeTsoffTest "default" { }; }
