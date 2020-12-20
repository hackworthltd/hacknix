{ lib
, ...
}:
{
  system = "x86_64-linux";
  modules = lib.singleton
    ({ pkgs, ... }:
      let
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBp7K+EqL+5Ry40pQrHRDd9H/jh/eaYYYV0uxH9cxa0q";
      in
      {
        boot.isContainer = true;
        hacknix.defaults.enable = true;
        hacknix.build-host.enable = true;
        hacknix.build-host.buildMachines = {
          remote-builder = {
            hostName = "remote-builder.example.com";
            alternateHostNames = [ "192.0.2.1" "2001:db8::1" ];
            hostPublicKeyLiteral = sshPublicKey;
            systems = [ "x86_64-linux" "i686-linux" ];
            maxJobs = 4;
            speedFactor = 1;
            supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
            sshUserName = "remote-builder";
          };
        };
        users.users.root.openssh.authorizedKeys.keys = [
          sshPublicKey
        ];
      });
}
