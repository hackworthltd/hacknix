# Just make sure we can spin up a Postfix MTA instance.

{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  # Don't do this in production -- it will put the secrets into the
  # Nix store! This is just a convenience for the tests.
  cert-chain = ./testfiles/certs/bob-at-acme.com-chain.crt;
  bob-certKey = ./testfiles/keys/bob-at-acme.com.key;
in
makeTestPython {
  name = "postfix-mta";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  machine = { ... }: {
    nixpkgs.localSystem.system = system;
    imports = pkgs.lib.hacknix.modules
      ++ pkgs.lib.hacknix.testing.testModules;
    services.postfix-mta = {
      enable = true;
      myDomain = "acme.com";
      myHostname = "mx.acme.com";
      virtual.transport = "lmtp:localhost:24";
      submission.smtpd.tlsCertFile = cert-chain;
      submission.smtpd.tlsKeyLiteral = builtins.readFile bob-certKey;
    };
  };

  testScript = ''
    machine.wait_for_unit("postfix.service")
    machine.succeed('[ "$(postqueue -p)" == "Mail queue is empty" ]')
  '';
}
