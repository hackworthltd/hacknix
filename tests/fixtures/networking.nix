{ testingPython, ... }:
with testingPython;
let
  makeNetworkingTest = name: machineAttrs:
    makeTest {
      name = "networking-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {
        server = { config, pkgs, ... }: machineAttrs;
        client = { ... }: { };
      };

      testScript = { nodes, ... }: ''
        start_all()
        client.wait_for_unit("network.target")
        server.wait_for_unit("network.target")

        with subtest("Can ping server"):
            client.succeed("ping -c 1 server >&2")
      '';

    };
in
{
  test1 =
    makeNetworkingTest "global-enable" { hacknix.defaults.enable = true; };
  test2 = makeNetworkingTest "networking-enable" {
    hacknix.defaults.networking.enable = true;
  };
}
