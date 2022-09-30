{ testingPython, ... }:
with testingPython;
let
  makeEnvTest = name: machineAttrs:
    makeTest {
      name = "environment-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };
      nodes.machine = { config, pkgs, ... }:
        {
          imports = [ ../include/users.nix ];
        } // machineAttrs;
      testScript = { ... }: ''
        machine.wait_for_unit("multi-user.target")

        with subtest("No history file for root"):
            machine.fail("bash -c 'printenv HISTFILE'")

        with subtest("No history file for user"):
            assert "alice" in machine.succeed("su - alice -c 'whoami'")
            machine.fail("su - alice -c 'printenv HISTFILE'")

        with subtest("Ensure git is in the path"):
            assert "Initialized empty Git repository in" in machine.succeed("git init")

        with subtest("Ensure wget is in the path"):
            assert "GNU Wget" in machine.succeed("wget --version")

        with subtest("Ensure emacs is in the path"):
            assert "GNU Emacs" in machine.succeed("emacs --version")
      '';
    };
in
{

  test1 = makeEnvTest "global-enable" { hacknix.defaults.enable = true; };
  test2 =
    makeEnvTest "env-enable" { hacknix.defaults.environment.enable = true; };

}
