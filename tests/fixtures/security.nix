{ hostPkgs, ... }:
{
  meta = with hostPkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes.machine1 = { config, pkgs, ... }: {
    hacknix.defaults.enable = true;
  };
  nodes.machine2 = { config, pkgs, ... }: {
    hacknix.defaults.security.enable = true;
  };

  testScript = { ... }: ''
    machine1.wait_for_unit("multi-user.target")
    machine2.wait_for_unit("multi-user.target")

    with subtest("Clean tmpdir on boot"):
        machine1.succeed("touch /tmp/foobar")
        machine1.shutdown()
        machine1.wait_for_unit("systemd-tmpfiles-clean.timer")
        machine1.succeed("! [ -e /tmp/foobar ]")

        machine2.succeed("touch /tmp/foobar")
        machine2.shutdown()
        machine2.wait_for_unit("systemd-tmpfiles-clean.timer")
        machine2.succeed("! [ -e /tmp/foobar ]")
  '';
}
