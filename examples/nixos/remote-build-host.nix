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
        networking.hostName = "remote-builder";
        hacknix.defaults.enable = true;
        hacknix.remote-build-host.enable = true;
        hacknix.remote-build-host.user.sshPublicKeys = [ sshPublicKey ];
        users.users.root.openssh.authorizedKeys.keys = [ sshPublicKey ];
      });
}
