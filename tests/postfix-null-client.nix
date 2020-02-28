{ system ? "x86_64-linux"
, pkgs
, makeTest
, ...
}:

let

  # Don't do this in production -- it will put the secrets into the
  # Nix store! This is just a convenience for the tests.

  ca-cert = ./testfiles/certs/root.crt;
  bob-cert = ./testfiles/certs/bob-at-acme.com.crt;
  bob-certKey = ./testfiles/keys/bob-at-acme.com.key;
  bob-certKeyInStore = pkgs.copyPathToStore ./testfiles/keys/bob-at-acme.com.key;

in makeTest rec {
  name = "postfix-null-client";

  meta = with pkgs.lib.maintainers; {
    maintainers = [ dhess ];
  };

  nodes = {
    client = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports =
        pkgs.lib.hacknix.modules ++
        pkgs.lib.hacknix.testing.testModules;

      # Use the test key deployment system.
      deployment.reallyReallyEnable = true;

      services.postfix-null-client = {
        enable = true;
        myDomain = "example.com";
        myOrigin = "example.com";
        relayHost = "mail.example.com";
        smtpTlsCAFile = ca-cert;
        smtpTlsCertFile = bob-cert;
        smtpTlsKeyLiteral = builtins.readFile bob-certKey;
      };
    };
  };

  testScript = { nodes, ... }:
  let
    stateDir = nodes.client.config.services.postfix-null-client.stateDir;
  in
  ''
    $client->waitForUnit("multi-user.target");
    $client->requireActiveUnit("postfix.service");

    subtest "check-keys", sub {
      $client->succeed("diff ${bob-certKeyInStore} ${stateDir}/keys/postfix-null-client-cert");
    };
  '';
}
