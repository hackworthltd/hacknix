{ system ? "x86_64-linux", pkgs, makeTest, ... }:

let

  justAnExamplePublicKey = ''
    2018.10.27._domainkey	IN	TXT	( "v=DKIM1; h=sha256; k=rsa; "
    	  "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwaDVihIfc1DN70JoeS6ohWZfEJG5tMhlBOSfH4FhA49grY8rAFlFqyCfvf1K5aNhtrq1oJRhjbdL0TaLpDMAkY7V5nQ8de53IpTHIyvy+Ik0kotY3GXLIqRhEfm9W3R8lfuiIkWyzTG25XIaqM/VhuMwGWziuVF7pMO5ii5hWyToIW7G+l9zckpOv/pf4cQahXEb9f/iegVusL"
    	  "pnYRGDtS6kUyZo2rYdqVCPZGcg3joG2fUhQ42ZoJN8k63+ujdXRBn+2SuM7U0X7rzt5kPnWmDRh/C79F38IYzsqOZdEo9Kg+aSP3C5NY3ulsX5VOCaTkwm4AQ80qRy+SBe/En/UwIDAQAB" )  ; ----- DKIM key 2018.10.27 for example.com
      '';

  justAnExampleKey = ''
    -----BEGIN RSA PRIVATE KEY-----
    MIIEogIBAAKCAQEAwaDVihIfc1DN70JoeS6ohWZfEJG5tMhlBOSfH4FhA49grY8r
    AFlFqyCfvf1K5aNhtrq1oJRhjbdL0TaLpDMAkY7V5nQ8de53IpTHIyvy+Ik0kotY
    3GXLIqRhEfm9W3R8lfuiIkWyzTG25XIaqM/VhuMwGWziuVF7pMO5ii5hWyToIW7G
    +l9zckpOv/pf4cQahXEb9f/iegVusLpnYRGDtS6kUyZo2rYdqVCPZGcg3joG2fUh
    Q42ZoJN8k63+ujdXRBn+2SuM7U0X7rzt5kPnWmDRh/C79F38IYzsqOZdEo9Kg+aS
    P3C5NY3ulsX5VOCaTkwm4AQ80qRy+SBe/En/UwIDAQABAoIBAFHpA+ygtgVGTZfF
    dASvpEKqh9SukOzVSUbEoDvns26aHL/PLNW87ifyaSEqIaD7eL6gRW1k18/nln8u
    n+waV0c8MWiIC3uoIWXTolpSoTpacI79u92ggkppV1cPWvdxU7Lu/CubaIQ9X624
    k2aOZTnmqdZXpaHXwoJ0+exmqnCvcsRmOvb8JD60UIqwpris5c5KlNoHCSPA33w8
    EYrU9x7R3OQN64esn6xQ6E7PRXrujz+AP4yc1SIGyJRIx6DxAWgzcN3SP671WnMv
    p0x7dgFSnGZS89DtpVFtH5kx0di5THf9vFmtD/oCn54PA6qYwrkLlTHuxe/TcBwg
    fVUnmGECgYEA95s0NW9Zfhh63Xbkhb/ApF05mfI+V5zh04YbuflQ9w1CL+2l8TYW
    kS4/tB9a11Fp11MpjKIQQ65RLeytuFvh6k6rPyZAt5ShJ901n+q/hbrSeFrGltrf
    qBxZMj4J7nLHPOovPwxjg0e7drxbf6/XWW+igyNIWartAvSsKPNaP+8CgYEAyDEx
    rEXs2XAwJYo6hBkKrZFeXzc+wvFvXiz84ijKd5FY03zbJdpmYOzSZI/FvOEZhPnt
    iHiZNLcD5iufuex+G1tnWhPhleq98wSxRwAby0BnjNcvS88g+K/4JEpFVntVgU63
    eDbXyWJUZGs3Os1wjMFs5Z2+znJ/jgNXIR0+Et0CgYAEVWANi1xam50S4TDQsnFx
    rvwCGL5ElEdTh2ZW0+k52a6N3i/oT9UHR3Lv+RiC6jbbAOaaQn/cX2GmVx0XO+xx
    SF0w5r99Nwm3A+UbXmVptsJWPuh43W3KqGxbN8C+vp2EEGkxRks7kfbS9ir3yiEP
    vKdweh6bCyXIxnV45gFvWwKBgGWBfBxLwFJoLiF6uzzrrZxgTyecTXhvDvcDfJ33
    7OE/k3h4oG3LFYojynIu7CZfRJ9GUoiWDajK+3EjwXN2VGLur7Lezc1EH1gvkuvb
    RDyExXyGR3b66U7verR77DhzhOFx1llgBX4ZG41nR7PLIzxbfynWGD95ku+hBfbG
    awkJAoGAUoiPIgmlRXIYajaixguq5iCF1bMPLfk8GM1X0Mg6XVx7/hy5YofotwOr
    Dz6Kq3Nd1jQpoUZjXexdp4LBKaguclr/HeRD1l7llBDujoy49Kvs3+tpWy9RYpWG
    KVVFchvliGeTAqSJg3WjQ0QYaePizZ5CqcJprdB6UO1o+WKAOns=
    -----END RSA PRIVATE KEY-----
  '';

  justAnExampleKeyFile = pkgs.writeText "example.com.key" justAnExampleKey;

in makeTest rec {
  name = "opendkim";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {

    machine = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules
        ++ pkgs.lib.hacknix.testing.testModules;

      # Use the test key deployment system.
      deployment.reallyReallyEnable = true;

      services.qx-opendkim = {
        enable = true;

        signingTable = [{
          fromRegex = "*@example.com";
          keyName = "example.com";
        }];

        keyTable = {
          example = {
            keyName = "example.com";
            domain = "example.com";
            selector = "2018.10.27";
            privateKeyLiteral = justAnExampleKey;
          };
        };
      };
    };
  };

  testScript = { nodes, ... }:
    let
      exampleKeyPath = "/var/lib/opendkim/keys/opendkim-example-private";
      socket = "/run/opendkim/opendkim.sock";
    in ''
      startAll;

      $machine->waitForUnit("opendkim.service");

      subtest "check-ssh-keys", sub {
        $machine->succeed("diff ${justAnExampleKeyFile} ${exampleKeyPath}");
        $machine->succeed("[[ `stat -c%a ${exampleKeyPath}` -eq 400 ]]");
        $machine->succeed("[[ `stat -c%U ${exampleKeyPath}` -eq opendkim ]]");
        $machine->succeed("[[ `stat -c%G ${exampleKeyPath}` -eq opendkim ]]");
        $machine->succeed("[[ `stat -c%a ${socket}` -eq 775 ]]");
        $machine->succeed("[[ `stat -c%U ${socket}` -eq opendkim ]]");
        $machine->succeed("[[ `stat -c%G ${socket}` -eq opendkim ]]");
      };
    '';
}
