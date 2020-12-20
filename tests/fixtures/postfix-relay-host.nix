{ testingPython, ... }:
with testingPython;
let
  # Don't do this in production -- it will put the secrets into the
  # Nix store! This is just a convenience for the tests.
  ca-cert = ../testfiles/certs/root.crt;
  bob-cert = ../testfiles/certs/bob-at-acme.com.crt;
  bob-sha1 = ../testfiles/certs/bob-at-acme.com.sha1;
  bob-certKey = ../testfiles/keys/bob-at-acme.com.key;
  bob-certKeyInStore =
    pkgs.copyPathToStore ../testfiles/keys/bob-at-acme.com.key;
in
makeTest rec {
  name = "postfix-relay-host";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    host = { config, pkgs, ... }: {
      imports = [ ../include/deploy-keys.nix ];

      networking.useDHCP = false;
      networking.firewall.allowedTCPPorts = [ 25 587 ];
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.1";
          prefixLength = 24;
        }
      ];
      networking.interfaces.eth1.ipv6.addresses = [
        {
          address = "fd00:1234:5678::1000";
          prefixLength = 64;
        }
      ];

      # Use the test key deployment system.
      deployment.reallyReallyEnable = true;

      services.postfix-relay-host = {
        enable = true;
        listenAddresses = [ "192.168.1.1" "fd00:1234:5678::1000" ];
        myDomain = "example.com";
        myOrigin = "example.com";
        relayDomains = [ "example.com" ];
        relayClientCertFingerprintsFile = bob-sha1;
        smtpTlsCAFile = ca-cert;
        smtpTlsCertFile = bob-cert;
        smtpTlsKeyLiteral = builtins.readFile bob-certKey;
      };
    };
  };

  testScript = { nodes, ... }: ''
    host.wait_for_unit("multi-user.target")
    host.wait_for_unit("postfix.service")

    with subtest("Check Postfix keys"):
        host.succeed(
            "diff ${bob-certKeyInStore} /var/lib/postfix/data/keys/postfix-relay-host-cert"
        )
  '';
}
