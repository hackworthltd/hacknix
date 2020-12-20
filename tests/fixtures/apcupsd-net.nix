# Note -- this service can't actually communicate with an actual UPS.
# It's mainly here just to make sure that the service starts up.

{ testingPython, ... }:
with testingPython;
makeTest {
  name = "apcupsd-net";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    machine = { config, pkgs, lib, ... }: {
      imports = lib.singleton ../include/deploy-keys.nix;

      # Use the test key deployment system.
      deployment.reallyReallyEnable = true;

      services.apcupsd-net = {
        enable = true;
        ups.name = "foo";
        ups.ip = "192.168.100.10";
        shutdownCredentials = "passw0rd";
      };
    };
  };

  testScript = { nodes, ... }: ''
    start_all()
    machine.wait_for_unit("apcupsd.service")
  '';
}
