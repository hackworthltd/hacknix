{ system ? "x86_64-linux", pkgs, makeTest, ... }:

let

  makeNetworkingTest = name: machineAttrs:
    makeTest {

      name = "networking-${name}";

      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {

        server = { config, ... }:
          {
            nixpkgs.localSystem.system = system;
            imports = pkgs.lib.hacknix.modules;
          } // machineAttrs;

        client = { ... }: { nixpkgs.localSystem.system = system; };

      };

      testScript = { nodes, ... }: ''
        startAll;
        $client->waitForUnit("network.target");
        $server->waitForUnit("network.target");

        subtest "can-ping", sub {
          $client->succeed("ping -c 1 server >&2");
        };
      '';

    };

in {

  test1 =
    makeNetworkingTest "global-enable" { hacknix.defaults.enable = true; };
  test2 = makeNetworkingTest "networking-enable" {
    hacknix.defaults.networking.enable = true;
  };

}
