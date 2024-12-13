{ hostPkgs, ... }:
{
  meta = with hostPkgs.lib.maintainers; {
    maintainers = [ dhess ];
  };

  nodes = {
    server1 =
      { config, pkgs, ... }:
      {
        hacknix.defaults.enable = true;
      };
    server2 =
      { config, pkgs, ... }:
      {
        hacknix.defaults.networking.enable = true;
      };
    client = { ... }: { };
  };

  testScript =
    { nodes, ... }:
    ''
      start_all()
      client.wait_for_unit("network.target")
      server1.wait_for_unit("network.target")
      server2.wait_for_unit("network.target")

      with subtest("Can ping servers"):
          client.succeed("ping -c 1 server1 >&2")
          client.succeed("ping -c 1 server2 >&2")
    '';
}
