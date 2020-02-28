{ system ? "x86_64-linux"
, pkgs
, makeTest
, ...
}:


let

  makeSystemTest = name: machineAttrs:
    makeTest {
      name = "system-${name}";
      meta = with pkgs.lib.maintainers; {
        maintainers = [ dhess ];
      };
      machine = { config, ... }: {
        nixpkgs.localSystem.system = system;
        imports = pkgs.lib.hacknix.modules;
      } // machineAttrs;
      testScript = { ... }:
      ''
        $machine->waitForUnit("multi-user.target");

        subtest "timezone-is-utc", sub {
          my $timedatectl = $machine->succeed("timedatectl");
          $timedatectl =~ /Time zone:.* \(UTC,/ or die "System has wrong timezone";
        };

        subtest "locale-is-utf8", sub {
          my $localectl = $machine->succeed("localectl");
          $localectl =~ /System Locale: LANG=en_US.UTF-8/ or die "System has wrong locale";
        };

        subtest "logrotate-enabled", sub {
          $machine->waitForUnit("logrotate.timer");
        };
      '';
    };

in
{

  globalEnableTest = makeSystemTest "global-enable" { hacknix.defaults.enable = true; };
  systemEnableTest = makeSystemTest "system-enable" { hacknix.defaults.system.enable = true; };

}
