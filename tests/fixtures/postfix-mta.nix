# Just make sure we can spin up a Postfix MTA instance.

{ testingPython, ... }:
with testingPython;
let
  # Don't do this in production -- it will put the secrets into the
  # Nix store! This is just a convenience for the tests.
  cert-chain = ../testfiles/certs/bob-at-acme.com-chain.crt;
  bob-certKey = ../testfiles/keys/bob-at-acme.com.key;
in
makeTest {
  name = "postfix-mta";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  machine = { config, pkgs, lib, ... }: {
    services.postfix-mta = {
      enable = true;
      myDomain = "acme.com";
      myHostname = "mx.acme.com";
      virtual.transport = "lmtp:localhost:24";
      submission.smtpd.tlsCertFile = cert-chain;

      # This file doesn't actually exist, but Postfix should start
      # anyway.
      submission.smtpd.tlsKeyFile = "/var/lib/postfix/tls.key";
    };
  };

  testScript = ''
    machine.wait_for_unit("postfix.service")
    machine.succeed('[ "$(postqueue -p)" == "Mail queue is empty" ]')
  '';
}
