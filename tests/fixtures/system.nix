{ hostPkgs, ... }:
{
  meta = with hostPkgs.lib.maintainers; {
    maintainers = [ dhess ];
  };
  nodes.machine =
    { config, pkgs, ... }:
    {
      hacknix.defaults.enable = true;
    };
  testScript =
    { ... }:
    ''
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
}
