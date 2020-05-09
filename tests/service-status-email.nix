{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
in
makeTest rec {
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
    $machine->waitForUnit("multi-user.target");
    $machine->startJob("status-email-root\@postfix");
  '';
}
