{
  hostPkgs,
  ...
}:
{
  name = "environment";
  meta = with hostPkgs.lib.maintainers; {
    maintainers = [ dhess ];
  };
  nodes.machine1 =
    { config, pkgs, ... }:
    {
      hacknix.defaults.enable = true;
      imports = [ ../include/users.nix ];
    };
  nodes.machine2 =
    { config, pkgs, ... }:
    {
      hacknix.defaults.environment.enable = true;
      imports = [ ../include/users.nix ];
    };
  testScript =
    { ... }:
    ''
      machine1.wait_for_unit("multi-user.target")

      with subtest("No history file for root"):
          machine1.fail("bash -c 'printenv HISTFILE'")

      with subtest("No history file for user"):
          assert "alice" in machine1.succeed("su - alice -c 'whoami'")
          machine1.fail("su - alice -c 'printenv HISTFILE'")

      with subtest("Ensure git is in the path"):
          assert "Initialized empty Git repository in" in machine1.succeed("git init")

      with subtest("Ensure wget is in the path"):
          assert "GNU Wget" in machine1.succeed("wget --version")

      with subtest("Ensure emacs is in the path"):
          assert "GNU Emacs" in machine1.succeed("emacs --version")

      machine2.wait_for_unit("multi-user.target")

      with subtest("No history file for root"):
          machine2.fail("bash -c 'printenv HISTFILE'")

      with subtest("No history file for user"):
          assert "alice" in machine2.succeed("su - alice -c 'whoami'")
          machine2.fail("su - alice -c 'printenv HISTFILE'")

      with subtest("Ensure git is in the path"):
          assert "Initialized empty Git repository in" in machine2.succeed("git init")

      with subtest("Ensure wget is in the path"):
          assert "GNU Wget" in machine2.succeed("wget --version")

      with subtest("Ensure emacs is in the path"):
          assert "GNU Emacs" in machine2.succeed("emacs --version")
    '';
}
