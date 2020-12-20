{ testingPython, ... }:
with testingPython;
let
in
makeTest rec {
  name = "virtual-ips";
  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    host = { config, pkgs, ... }: {
      networking.virtual-ips.v4 = [ "10.0.0.1" "192.168.8.77" ];
      networking.virtual-ips.v6 =
        [ "fd00:1234:5678::1" "fd00:1234:5678::2000:8" ];
    };
  };

  testScript = { nodes, ... }: ''
    start_all()

    host.wait_for_unit("multi-user.target")

    host.succeed("ping -c 1 10.0.0.1 >&2")
    host.succeed("ping -c 1 192.168.8.77 >&2")
    host.succeed("ping -c 1 fd00:1234:5678::1 >&2")
    host.succeed("ping -c 1 fd00:1234:5678::2000:8 >&2")
  '';
}
