{ testingPython, ... }:
with testingPython;
let
in
makeTest rec {
  name = "service-status-email";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    machine = { config, pkgs, ... }: {
      services.service-status-email = {
        enable = true;
        recipients = {
          root = { address = "root"; };
          postmaster = { address = "postmaster"; };
        };
      };

      services.postfix = { enable = true; };
    };
  };

  testScript = { nodes, ... }: ''
    machine.wait_for_unit("multi-user.target")
    machine.start_job("status-email-root@postfix")
  '';
}
