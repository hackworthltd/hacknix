{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  makeSystemTest = name: machineAttrs:
    makeTestPython {
      name = "system-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };
      machine = { config, ... }:
        {
          nixpkgs.localSystem.system = system;
          imports = pkgs.lib.hacknix.modules;
        } // machineAttrs;
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
