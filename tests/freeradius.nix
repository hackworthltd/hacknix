{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
in
makeTest rec {
  name = "freeradius";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    freeradius = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules
        ++ pkgs.lib.hacknix.testing.testModules;

      # Use the test key deployment system.
      deployment.reallyReallyEnable = true;

      hacknix.freeradius = {
        enable = true;
        interfaces = [ "eth0" ];
        clients = {
          localhost = {
            ipv4 = "127.0.0.1";
            ipv6 = "::1";
            secretLiteral = "sasquatch";
          };
        };
        tls = {
          caPath = pkgs.hashedCertDir {
            name = "freeradius-test";
            certFiles =
              [ ./testfiles/certs/root.crt ./testfiles/crls/acme.com.crl ];
          };
          serverCertificate = ./testfiles/certs/vpn1.acme.com.crt;
          serverCertificateKeyLiteral =
            builtins.readFile ./testfiles/keys/vpn1.acme.com.key;
        };
      };
    };
  };

  testScript = { nodes, ... }: ''
    startAll;
    $freeradius->waitForUnit("multi-user.target");
    $freeradius->waitForUnit("freeradius.service");
  '';
}
