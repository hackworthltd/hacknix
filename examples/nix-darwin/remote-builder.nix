{ lib
, ...
}:
{
  system = "aarch64-darwin";
  modules = lib.singleton
    ({ pkgs, ... }:
      let
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkRyutu3OMvSDFQOsOtls4A5krFlYEPbiPG/qUyxGdb example remote-builder key";
      in
      {
        # For now, setting this is required.
        environment.darwinConfig = "${pkgs.lib.hacknix.path}/examples/nix-darwin/remote-builder.nix";

        nix.settings.max-jobs = 12;

        hacknix-nix-darwin.remote-build-host = {
          enable = true;
          user.sshPublicKeys = lib.singleton sshPublicKey;
        };
      });
}
