{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
  makeUsersTest = name: machineAttrs:
    makeTest {

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
        in ''
          $machine->waitForUnit("multi-user.target");

          subtest "immutable-users", sub {
            $machine->succeed("(echo notalicespassword; echo notalicespassword) | passwd alice");
            $machine->waitUntilTTYMatches(1, "login: ");
            $machine->sendChars("alice\n");
            $machine->waitUntilTTYMatches(1, "Password: ");
            $machine->sendChars("notalicespassword\n");
            $machine->waitUntilTTYMatches(1, "alice\@machine");

            $machine->shutdown();
            $machine->waitForUnit("multi-user.target");
            $machine->waitUntilTTYMatches(1, "login: ");
            $machine->sendChars("alice\n");
            $machine->waitUntilTTYMatches(1, "Password: ");
            $machine->sendChars("${alicePassword}\n");
            $machine->waitUntilTTYMatches(1, "alice\@machine");
          };
        '';
    };
in
{

  globalEnableTest =
    makeUsersTest "global-enable" { hacknix.defaults.enable = true; };
  usersEnableTest =
    makeUsersTest "users-enable" { hacknix.defaults.users.enable = true; };

}
