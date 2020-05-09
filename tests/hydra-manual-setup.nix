{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
  # Don't do this in production -- it will put the secret into the Nix
  # store! This is just a convenience for the tests.
  bckey = pkgs.copyPathToStore ./testfiles/hydra-1/secret;
  bcpubkey = pkgs.copyPathToStore ./testfiles/hydra-1/public;
  bcKeyDir = "/etc/nix/hydra-1";
in
makeTest rec {
  name = "hydra-manual-setup";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {

    client = { config, ... }: { nixpkgs.localSystem.system = system; };

    hydra = { config, ... }: {
      virtualisation.memorySize = 2048;
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules
        ++ pkgs.lib.hacknix.testing.testModules;

      # Use the test key deployment system.
      deployment.reallyReallyEnable = true;

      services.hydra-manual-setup = {
        enable = true;
        adminUser = {
          fullName = "Hydra Admin";
          userName = "hydra";
          email = "hydra@example.com";
          initialPasswordLiteral = pkgs.lib.fileContents ./testfiles/hydra-pw;
        };
        binaryCacheKey = {
          publicKeyFile = ./testfiles/hydra-1/public;
          privateKeyLiteral = pkgs.lib.fileContents ./testfiles/hydra-1/secret;
          directory = "${bcKeyDir}";
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
      startAll;

      $client->waitForUnit("multi-user.target");
      $hydra->waitForUnit("multi-user.target");

      subtest "check-manual-setup", sub {

        # test whether the database is running
        $hydra->succeed("systemctl status postgresql.service");

        # test whether the actual hydra daemons are running
        $hydra->succeed("systemctl status hydra-queue-runner.service");
        $hydra->succeed("systemctl status hydra-init.service");
        $hydra->succeed("systemctl status hydra-evaluator.service");
        $hydra->succeed("systemctl status hydra-send-stats.service");
        $hydra->succeed("systemctl status hydra-server.service");
        $hydra->succeed("systemctl status hydra-manual-setup.service");

        # Make sure binary cache keys were copied to the expected
        # location with the proper permissions.
        $hydra->succeed("[[ -d ${bcKeyDir} ]]");
        $hydra->succeed("[[ `stat -c%a ${bcKeyDir}` -eq 551 ]]");
        $hydra->succeed("[[ `stat -c%U ${bcKeyDir}` -eq hydra ]]");
        $hydra->succeed("[[ `stat -c%G ${bcKeyDir}` -eq hydra ]]");
        $hydra->succeed("[[ -e ${bcKeyDir}/public ]]");
        $hydra->succeed("[[ `stat -c%a ${bcKeyDir}/public` -eq 444 ]]");
        $hydra->succeed("[[ `stat -c%U ${bcKeyDir}/public` -eq hydra ]]");
        $hydra->succeed("[[ `stat -c%G ${bcKeyDir}/public` -eq hydra ]]");
        $hydra->succeed("[[ -e ${bcKeyDir}/secret ]]");
        $hydra->succeed("[[ `stat -c%a ${bcKeyDir}/secret` -eq 440 ]]");
        $hydra->succeed("[[ `stat -c%U ${bcKeyDir}/secret` -eq hydra ]]");
        $hydra->succeed("[[ `stat -c%G ${bcKeyDir}/secret` -eq hydra ]]");
        $hydra->succeed("diff ${bcKeyDir}/public ${bcpubkey}");
        $hydra->succeed("diff ${bcKeyDir}/secret ${bckey}");

        # Wait for the initial setup to finish.
        $hydra->waitForFile("/var/lib/hydra/.manual-setup-is-complete-v1");

        # Make sure we can log in. Sometimes it takes some time for the
        # server to start accepting connections, so we allow retries.
        
        my $out = $client->succeed("${pkgs.curl}/bin/curl --retry 10 --retry-delay 5 --retry-connrefused  --referer http://hydra:3000 -d '{\"username\":\"hydra\",\"password\":\"foobar\"}' -H \"Content-Type: application/json\" -X POST http://hydra:3000/login");
        $out =~ /"username":"hydra"/ or die "hydra-manual-setup user creation failed";
      };

    '';
}
