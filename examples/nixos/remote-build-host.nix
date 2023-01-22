args:
args // {
  system = "x86_64-linux";
  modules = [
    ({ pkgs, ... }:
      let
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBp7K+EqL+5Ry40pQrHRDd9H/jh/eaYYYV0uxH9cxa0q";
      in
      {
        networking.hostName = "remote-builder";
        system.stateVersion = "23.05";
        hacknix.defaults.enable = true;
        hacknix.remote-build-host.enable = true;
        hacknix.remote-build-host.user.sshPublicKeys = [ sshPublicKey ];
        users.users.root.openssh.authorizedKeys.keys = [ sshPublicKey ];
      })
  ];
}
