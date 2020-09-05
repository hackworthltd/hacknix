{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
in
makeTestPython rec {
  name = "service-status-email";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    machine = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules;

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
