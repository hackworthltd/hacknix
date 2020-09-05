{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  makeUsersTest = name: machineAttrs:
    makeTestPython {

      name = "users-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      machine = { config, ... }:
        {
          nixpkgs.localSystem.system = system;
          imports = [ ./common/users.nix ] ++ pkgs.lib.hacknix.modules;

        } // machineAttrs;

      testScript = { nodes, ... }:
        let
          alicePassword = nodes.machine.config.users.users.alice.password;
        in
        ''
          machine.wait_for_unit("multi-user.target")

          with subtest("Immutable users"):
              machine.succeed("(echo notalicespassword; echo notalicespassword) | passwd alice")
              machine.wait_until_tty_matches(1, "login: ")
              machine.send_chars("alice\n")
              machine.wait_until_tty_matches(1, "Password: ")
              machine.send_chars("notalicespassword\n")
              machine.wait_until_tty_matches(1, "alice\@machine")

              machine.shutdown()
              machine.wait_for_unit("multi-user.target")
              machine.wait_until_tty_matches(1, "login: ")
              machine.send_chars("alice\n")
              machine.wait_until_tty_matches(1, "Password: ")
              machine.send_chars("${alicePassword}\n")
              machine.wait_until_tty_matches(1, "alice\@machine")
        '';
    };
in
{
  globalEnableTest =
    makeUsersTest "global-enable" { hacknix.defaults.enable = true; };
  usersEnableTest =
    makeUsersTest "users-enable" { hacknix.defaults.users.enable = true; };
}
