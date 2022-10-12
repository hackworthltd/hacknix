{ hostPkgs, ... }:
let
  keyfile = "/var/lib/keys/tarsnapper.key";
in
{
  meta = with hostPkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    machine = { config, pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;

      system.activationScripts.install-dummy-key = pkgs.lib.stringAfter [ "users" "groups" ] ''
        install -d -m 0750 -o root -g wheel /var/lib/keys
        echo "notarealkey" > ${keyfile}
        chmod 0400 ${keyfile}
        chown root:wheel ${keyfile}
      '';

      services.tarsnapper = {
        enable = true;
        inherit keyfile;
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
    start_all()

    ## Not a whole lot we can do here without an actual tarsnap server
    ## except make sure the timer is active. Note that the service is
    ## designed not to create the cache directory until it can
    ## successfully ping v1-0-0-server.tarsnap.com, so we don't test
    ## that here, either.

    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("tarsnapper.timer")
  '';
}
