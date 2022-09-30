{ testingPython, ... }:
with testingPython;
let
  makeUsersTest = name: machineAttrs:
    makeTest {
      name = "users-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes.machine = { config, pkgs, ... }:
        {
          imports = [ ../include/users.nix ];
        } // machineAttrs;

      testScript = { nodes, ... }:
        let
          alicePassword = nodes.machine.users.users.alice.password;
        in
        ''
          machine.wait_for_unit("multi-user.target")

          with subtest("Immutable users"):
              machine.succeed("(echo notalicespassword; echo notalicespassword) | passwd alice")
              machine.wait_until_tty_matches("1", "login: ")
              machine.send_chars("alice\n")
              machine.wait_until_tty_matches("1", "Password: ")
              machine.send_chars("notalicespassword\n")
              machine.wait_until_tty_matches("1", "alice\@machine")

              machine.shutdown()
              machine.wait_for_unit("multi-user.target")
              machine.wait_until_tty_matches("1", "login: ")
              machine.send_chars("alice\n")
              machine.wait_until_tty_matches("1", "Password: ")
              machine.send_chars("${alicePassword}\n")
              machine.wait_until_tty_matches("1", "alice\@machine")
        '';
    };
in
{
  globalEnableTest =
    makeUsersTest "global-enable" { hacknix.defaults.enable = true; };
  usersEnableTest =
    makeUsersTest "users-enable" { hacknix.defaults.users.enable = true; };
}
