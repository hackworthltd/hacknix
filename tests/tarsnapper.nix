{ system ? "x86_64-linux", pkgs, makeTest, ... }:

let
in makeTest rec {
  name = "tarsnapper";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {

    machine = { config, ... }: {
      nixpkgs.localSystem.system = system;
      nixpkgs.config.allowUnfree = true;
      imports = pkgs.lib.hacknix.modules;
      services.tarsnapper = {
        enable = true;
        keyLiteral = "notarealkey";
        period = "*:45:00";
        email.from = "root@localhost";
        email.toSuccess = "backups@localhost";
        email.toFailure = "backups@localhost";
        config = ''
          target: /local/$name-$date
          jobs:
            backup:
              sources:
                - /var
              deltas: 1h 1d 7d 30d 1000d
        '';
      };
    };
  };

  testScript = { nodes, ... }: ''
    startAll;

    ## Not a whole lot we can do here without an actual tarsnap server
    ## except make sure the timer is active. Note that the service is
    ## designed not to create the cache directory until it can
    ## successfully ping v1-0-0-server.tarsnap.com, so we don't test
    ## that here, either.

    $machine->waitForUnit("multi-user.target");
    $machine->waitForUnit("tarsnapper.timer");
  '';
}
