{ testingPython, ... }:
with testingPython;
let
  makeSystemTest = name: machineAttrs:
    makeTest {
      name = "system-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };
      nodes.machine = { config, pkgs, ... }: machineAttrs;
      testScript = { ... }: ''
        machine.wait_for_unit("multi-user.target")

        with subtest("Timezone is UTC"):
            timedatectl = machine.succeed("timedatectl")
            assert "UTC" in timedatectl

        with subtest("Locale is UTF8"):
            localectl = machine.succeed("localectl")
            assert "System Locale: LANG=en_US.UTF-8" in localectl

        with subtest("Logrotate is enabled"):
            machine.wait_for_unit("logrotate.timer")
      '';
    };
in
{
  globalEnableTest =
    makeSystemTest "global-enable" { hacknix.defaults.enable = true; };
  systemEnableTest =
    makeSystemTest "system-enable" { hacknix.defaults.system.enable = true; };
}
