{ hostPkgs, ... }:
let
  aliceBashProfile = hostPkgs.writeText "alice.bash_profile" ''
    export TZ="America/Los_Angeles"
    export TMOUT=300
    export HISTFILE=~/.bash_history
  '';
in
{
  meta = with hostPkgs.lib.maintainers; {
    maintainers = [ dhess ];
  };

  nodes.machine =
    { config, pkgs, ... }:
    {
      hacknix.defaults.enable = true;
      imports = [ ../include/users.nix ];
    };

  testScript =
    { nodes, ... }:
    let
      alicePassword = nodes.machine.users.users.alice.password;
    in
    ''
      machine.wait_for_unit("multi-user.target")

      with subtest("Sudo succeeds"):
          machine.succeed("sudo -s true")

      with subtest("Sudo environment"):
          # Prep the alice account.
          machine.succeed(
              "cp ${aliceBashProfile} ~alice/.bash_profile"
          )
          machine.succeed("cat ~alice/.bash_profile")
          machine.wait_for_file("~alice/.bash_profile")
          machine.succeed("chown alice:users ~alice/.bash_profile")
          machine.succeed("usermod -a -G wheel alice")

          # Make sure it's working like we expect.
          machine.wait_until_tty_matches("1", "login: ")
          machine.send_chars("alice\n")
          machine.wait_until_tty_matches("1", "Password: ")
          machine.send_chars("${alicePassword}\n")
          machine.wait_until_tty_matches("1", "alice\@machine")
          machine.send_chars("printenv > /tmp/alice.printenv\n")
          machine.wait_for_file("/tmp/alice.printenv")
          aliceEnv = machine.succeed("cat /tmp/alice.printenv")
          assert "TMOUT=300" in aliceEnv
          assert "HISTFILE=/home/alice/.bash_history" in aliceEnv
          assert "TZ=America/Los_Angeles" in aliceEnv

          # Now sudo and check the sudo environment.
          machine.send_chars("sudo -s\n")
          machine.wait_until_tty_matches("1", "password for alice")
          machine.send_chars("${alicePassword}\n")
          machine.wait_until_tty_matches("1", "root\@machine")
          machine.send_chars("printenv > /tmp/sudo.printenv\n")
          machine.wait_for_file("/tmp/sudo.printenv")

          sudoEnv = machine.succeed("cat /tmp/sudo.printenv")
          machine.log("sudo.printenv is " + sudoEnv)
          assert "TMOUT=120" in sudoEnv
          assert "TZ=\n" in sudoEnv
          assert "HOME=/root" in sudoEnv
          assert "HISTFILE" not in sudoEnv or "HISTFILE=\n" in sudoEnv
          
      with subtest("Sudo tty-tickets"):
          # Login on tty1 and sudo.
          machine.wait_until_tty_matches("1", "login: ")
          machine.send_chars("alice\n")
          machine.wait_until_tty_matches("1", "Password: ")
          machine.send_chars("${alicePassword}\n")
          machine.wait_until_tty_matches("1", "alice\@machine")
          machine.send_chars("sudo -s\n")
          machine.wait_until_tty_matches("1", "password for alice")
          machine.send_chars("${alicePassword}\n")
          machine.wait_until_tty_matches("1", "root\@machine")

          # Now login on tty2 and make sure sudo still asks for a
          # password.
          machine.send_key("alt-f2")
          machine.wait_until_succeeds("[ $(fgconsole) = 2 ]")
          machine.wait_for_unit("getty@tty2.service")
          machine.wait_until_succeeds("pgrep -f 'agetty.*tty2'")
          machine.wait_until_tty_matches("2", "login: ")
          machine.send_chars("alice\n")
          machine.wait_until_tty_matches("2", "Password: ")
          machine.send_chars("${alicePassword}\n")
          machine.wait_until_tty_matches("2", "alice\@machine")
          machine.send_chars("sudo -s\n")
          machine.wait_until_tty_matches("2", "password for alice")
          machine.send_chars("${alicePassword}\n")
          machine.wait_until_tty_matches("2", "root\@machine")

      with subtest("/etc/sudo.env permissions"):
          perms = machine.succeed("getfacl /etc/sudo.env")
          assert "owner: root" in perms
          assert "group: root" in perms
          assert "user::rw-" in perms
          assert "group::r--" in perms
          assert "other::---" in perms
    '';
}
