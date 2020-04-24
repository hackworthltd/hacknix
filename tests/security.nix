{ system ? "x86_64-linux", pkgs, makeTest, ... }:

let

  makeSecurityTest = name: machineAttrs:
    makeTest {

      name = "security-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      machine = { config, ... }:
        {
          nixpkgs.localSystem.system = system;
          imports = pkgs.lib.hacknix.modules;

        } // machineAttrs;

      testScript = { ... }: ''
        $machine->waitForUnit("multi-user.target");

        subtest "clean-tmpdir-on-boot", sub {
          $machine->succeed("touch /tmp/foobar");
          $machine->shutdown;
          $machine->waitForUnit("systemd-tmpfiles-clean.timer");
          $machine->succeed("! [ -e /tmp/foobar ]");
        };
      '';

    };

in {

  test1 = makeSecurityTest "global-enable" { hacknix.defaults.enable = true; };
  test2 = makeSecurityTest "security-enable" {
    hacknix.defaults.security.enable = true;
  };

}
