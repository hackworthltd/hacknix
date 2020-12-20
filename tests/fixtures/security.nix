{ testingPython, ... }:
with testingPython;
let
  makeSecurityTest = name: machineAttrs:
    makeTest {

      name = "security-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      machine = { config, pkgs, ... }: machineAttrs;

      testScript = { ... }: ''
        machine.wait_for_unit("multi-user.target")

        with subtest("Clean tmpdir on boot"):
            machine.succeed("touch /tmp/foobar")
            machine.shutdown()
            machine.wait_for_unit("systemd-tmpfiles-clean.timer")
            machine.succeed("! [ -e /tmp/foobar ]")
      '';

    };
in
{
  test1 = makeSecurityTest "global-enable" { hacknix.defaults.enable = true; };
  test2 = makeSecurityTest "security-enable" {
    hacknix.defaults.security.enable = true;
  };
}
