{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  # Don't do this in production -- it will put the secrets into the
  # Nix store! This is just a convenience for the tests.
  ca-cert = ./testfiles/certs/root.crt;
  bob-cert = ./testfiles/certs/bob-at-acme.com.crt;
  bob-certKey = ./testfiles/keys/bob-at-acme.com.key;
  bob-certKeyInStore =
    pkgs.copyPathToStore ./testfiles/keys/bob-at-acme.com.key;
in
makeTestPython rec {
  name = "postfix-null-client";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    client = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules
        ++ pkgs.lib.hacknix.testing.testModules;

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
      client.wait_for_unit("multi-user.target")
      client.require_unit_state("postfix.service")

      with subtest("Check TLS keys"):
          client.succeed(
              "diff ${bob-certKeyInStore} ${stateDir}/keys/postfix-null-client-cert"
          )
    '';
}
