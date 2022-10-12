{ hostPkgs, ... }:
{
  meta = with hostPkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes.machine = { config, pkgs, ... }:
    {
      imports = [ ../include/users.nix ];
      hacknix.defaults.enable = true;
    };

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
}
