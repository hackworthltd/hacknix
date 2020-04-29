{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
  aliceBashProfile = pkgs.writeText "alice.bash_profile" ''
    export TZ="America/Los_Angeles"
    export TMOUT=300
    export HISTFILE=~/.bash_history
  '';

  makeSudoTest = name: machineAttrs:
    makeTest {

      name = "sudo-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      machine = { config, ... }:
        {
          nixpkgs.localSystem.system = system;
          imports = [ ./common/users.nix ] ++ pkgs.lib.hacknix.modules;

        } // machineAttrs;

      testScript = { nodes, ... }:
        let
          alicePassword = nodes.machine.config.users.users.alice.password;
        in ''
          $machine->waitForUnit("multi-user.target");

          subtest "sudo-succeeds", sub {
            $machine->succeed("sudo -s true");
          };

          subtest "sudo-environment", sub {
            # Prep the alice account.
            $machine->succeed("cp ${aliceBashProfile} ~alice/.bash_profile");
            $machine->succeed("cat ~alice/.bash_profile");
            $machine->waitForFile("~alice/.bash_profile");
            $machine->succeed("chown alice:users ~alice/.bash_profile");
            $machine->succeed("usermod -a -G wheel alice");

            # Make sure it's working like we expect.
            $machine->waitUntilTTYMatches(1, "login: ");
            $machine->sendChars("alice\n");
            $machine->waitUntilTTYMatches(1, "Password: ");
            $machine->sendChars("${alicePassword}\n");
            $machine->waitUntilTTYMatches(1, "alice\@machine");
            $machine->sendChars("printenv > /tmp/alice.printenv\n");
            $machine->waitForFile("/tmp/alice.printenv");
            my $aliceEnv = $machine->succeed("cat /tmp/alice.printenv");
            $aliceEnv =~ /TMOUT=300\n/ or die "alice's TMOUT isn't set properly";
            $aliceEnv =~ /HISTFILE=\/home\/alice\/.bash_history\n/ or die "alice's HISTFILE isn't set properly";
            $aliceEnv =~ /TZ=America\/Los_Angeles\n/ or die "alice's TZ isn't set properly";

            # Now sudo and check the sudo environment.
            $machine->sendChars("sudo -s\n");
            $machine->waitUntilTTYMatches(1, "password for alice");
            $machine->sendChars("${alicePassword}\n");
            $machine->waitUntilTTYMatches(1, "root\@machine");
            $machine->sendChars("printenv > /tmp/sudo.printenv\n");
            $machine->waitForFile("/tmp/sudo.printenv");

            my $sudoEnv = $machine->succeed("cat /tmp/sudo.printenv");
            $machine->log("sudo.printenv is " . $sudoEnv);
            $sudoEnv =~ /TMOUT=120\n/ or die "sudo's TMOUT isn't set properly";
            $sudoEnv =~ /TZ=\n/ or die "sudo's TZ isn't set properly";
            $sudoEnv =~ /HOME=\/root\n/ or die "sudo's HOME isn't set properly";
            # XXX dhess - sometimes it's HISTFILE=, sometimes there's no
            # HISTFILE. I'm baffled as to why.
            $sudoEnv !~ /HISTFILE/ or $sudoEnv =~ /HISTFILE=\n/ or die "sudo's HISTFILE is set";
          };

          subtest "sudo-tty-tickets", sub {
            # Login on tty1 and sudo.
            $machine->waitUntilTTYMatches(1, "login: ");
            $machine->sendChars("alice\n");
            $machine->waitUntilTTYMatches(1, "Password: ");
            $machine->sendChars("${alicePassword}\n");
            $machine->waitUntilTTYMatches(1, "alice\@machine");
            $machine->sendChars("sudo -s\n");
            $machine->waitUntilTTYMatches(1, "password for alice");
            $machine->sendChars("${alicePassword}\n");
            $machine->waitUntilTTYMatches(1, "root\@machine");

            # Now login on tty2 and make sure sudo still asks for a
            # password.
            $machine->sendKeys("alt-f2");
            $machine->waitUntilSucceeds("[ \$(fgconsole) = 2 ]");
            $machine->waitForUnit('getty@tty2.service');
            $machine->waitUntilSucceeds("pgrep -f 'agetty.*tty2'");
            $machine->waitUntilTTYMatches(2, "login: ");
            $machine->sendChars("alice\n");
            $machine->waitUntilTTYMatches(2, "Password: ");
            $machine->sendChars("${alicePassword}\n");
            $machine->waitUntilTTYMatches(2, "alice\@machine");
            $machine->sendChars("sudo -s\n");
            $machine->waitUntilTTYMatches(2, "password for alice");
            $machine->sendChars("${alicePassword}\n");
            $machine->waitUntilTTYMatches(2, "root\@machine");
          };

          subtest "sudo-env-file-permissions", sub {
            my $perms = $machine->succeed("getfacl /etc/sudo.env");
            $perms =~ /owner: root/ or die "sudo.env has the wrong owner";
            $perms =~ /group: root/ or die "sudo.env has the wrong group";
            $perms =~ /user::rw-/ or die "sudo.env has the wrong user permissions";
            $perms =~ /group::r--/ or die "sudo.env has the wrong group permissions";
            $perms =~ /other::---/ or die "sudo.env has the wrong other permissions";
          };
        '';

    };
in
{

  test1 = makeSudoTest "global-enable" { hacknix.defaults.enable = true; };
  test2 = makeSudoTest "sudo-enable" { hacknix.defaults.sudo.enable = true; };

}
