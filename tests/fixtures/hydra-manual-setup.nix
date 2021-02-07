{ testingPython, ... }:
with testingPython;
let
in
makeTest {
  name = "hydra-manual-setup";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    client = { pkgs, config, ... }: { };

    hydra = { pkgs, config, ... }: {
      virtualisation.memorySize = 2048;
      services.hydra-manual-setup = {
        enable = true;
        adminUser = {
          fullName = "Hydra Admin";
          userName = "hydra";
          email = "hydra@example.com";
          initialPasswordLiteral = pkgs.lib.fileContents ../testfiles/hydra-pw;
        };
      };

      services.hydra = {
        enable = true;
        notificationSender = "notifier@example.com";
        port = 3000;
        hydraURL = "http://hydra:3000";
      };
      networking.firewall.allowedTCPPorts = [ 3000 ];
    };
  };

  testScript = { nodes, ... }:
    let
    in
    ''
      start_all()

      client.wait_for_unit("multi-user.target")
      hydra.wait_for_unit("multi-user.target")

      with subtest("Check manual setup"):
          # test whether the database is running
          hydra.succeed("systemctl status postgresql.service")

          # test whether the actual hydra daemons are running
          hydra.succeed("systemctl status hydra-queue-runner.service")
          hydra.succeed("systemctl status hydra-init.service")
          hydra.succeed("systemctl status hydra-evaluator.service")

          # Broken, let's skip it for now.
          # hydra.succeed("systemctl status hydra-send-stats.service")

          hydra.succeed("systemctl status hydra-server.service")
          hydra.succeed("systemctl status hydra-manual-setup.service")

          # Wait for the initial setup to finish.
          hydra.wait_for_file("/var/lib/hydra/.manual-setup-is-complete-v1")

          # Make sure we can log in. Sometimes it takes some time for the
          # server to start accepting connections, so we allow retries.

          output = client.succeed(
              '${nodes.hydra.pkgs.curl}/bin/curl --retry 10 --retry-delay 5 --retry-connrefused  --referer http://hydra:3000 -d \'{"username":"hydra","password":"foobar"}\' -H "Content-Type: application/json" -X POST http://hydra:3000/login'
          )
          assert '"username":"hydra"' in output
    '';
}
