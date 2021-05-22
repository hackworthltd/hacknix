{ testingPython, ... }:
with testingPython;
let
in
makeTest rec {
  name = "avail-reflector";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    server = { pkgs, config, ... }: {
      services.avahi-reflector.enable = true;
      services.avahi-reflector.interfaces = [ "eth0" ];
    };
  };

  testScript = { nodes, ... }: ''
    start_all()

    server.wait_for_unit("avahi.service")
  '';
}
