# Note -- this service can't actually communicate with an actual UPS.
# It's mainly here just to make sure that the service starts up.

{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
in
makeTestPython {
  name = "apcupsd-net";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    machine = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules
        ++ pkgs.lib.hacknix.testing.testModules;

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
