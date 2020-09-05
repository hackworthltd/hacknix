{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  canary1 = pkgs.copyPathToStore testfiles/canary1;
  canary2 = pkgs.copyPathToStore testfiles/canary2;
  imports = pkgs.lib.hacknix.modules
    ++ pkgs.lib.hacknix.testing.testModules;

in
makeTestPython rec {
  name = "tftpd-hpa";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {

    server1 = { pkgs, config, ... }: {
      nixpkgs.localSystem.system = system;
      inherit imports;
      networking.firewall.allowedUDPPorts = [ 69 ];
      services.tftpd-hpa.enable = true;

      systemd.services.tftpd-hpa = {
        # Need to make sure we've created the root directory before
        # this starts.
        wants = [ "make-tftp-root.service" ];
        after = [ "make-tftp-root.service" ];
      };

      systemd.services.make-tftp-root = {
        wantedBy = [ "multi-user.target" ];
        script =
          let
            root = config.services.tftpd-hpa.root;
          in
          ''
            mkdir -p ${root}
            cp ${canary1} ${root}/canary1
          '';
      };
    };

    # This server runs tftpd on a virtual IP, to test the
    # listenAddress functionality.

    server2 = { pkgs, config, ... }: {
      nixpkgs.localSystem.system = system;
      inherit imports;

      networking.firewall.allowedUDPPorts = [ 69 ];
      boot.kernelModules = [ "dummy" ];
      networking.interfaces.dummy0.ipv4.addresses = [
        {
          address = "192.168.1.100";
          prefixLength = 32;
        }
      ];
      services.tftpd-hpa = {
        enable = true;
        listenAddress = "192.168.1.100";
      };

      systemd.services.tftpd-hpa = {
        # Need to make sure we've created the root directory before
        # this starts.
        wants = [ "make-tftp-root.service" ];
        after = [ "make-tftp-root.service" ];
      };

      systemd.services.make-tftp-root = {
        wantedBy = [ "multi-user.target" ];
        script =
          let
            root = config.services.tftpd-hpa.root;
          in
          ''
            mkdir -p ${root}
            cp ${canary2} ${root}/canary2
          '';
      };
    };

    client = { config, ... }: {
      nixpkgs.localSystem.system = system;

      # Firewalling and tftp are complicated on the client end. We're
      # not trying to test that here.
      networking.firewall.enable = false;
    };

  };

  testScript = { nodes, ... }: ''
    start_all()

    server1.wait_for_unit("tftpd-hpa.service")
    server2.wait_for_unit("tftpd-hpa.service")
    client.wait_for_unit("multi-user.target")

    client.succeed(
        "${nodes.client.pkgs.tftp-hpa}/bin/tftp server1 -c get canary1"
    )
    client.succeed("diff canary1 ${canary1}")

    client.succeed("ping -c 1 192.168.1.100 >&2")
    client.succeed(
        "${nodes.client.pkgs.tftp-hpa}/bin/tftp 192.168.1.100 -c get canary2"
    )
    client.succeed("diff canary2 ${canary2}")

    server1.stop_job("tftpd-hpa.service")
  '';
}
