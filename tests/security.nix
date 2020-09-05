{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  makeSecurityTest = name: machineAttrs:
    makeTestPython {

      name = "security-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      machine = { config, ... }:
        {
          nixpkgs.localSystem.system = system;
          imports = pkgs.lib.hacknix.modules;

        } // machineAttrs;

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
