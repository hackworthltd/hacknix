{ lib
, ...
}:
{
  system = "x86_64-darwin";
  modules = lib.singleton
    ({ pkgs, ... }:
      let
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkRyutu3OMvSDFQOsOtls4A5krFlYEPbiPG/qUyxGdb example remote-builder key";
      in
      {
        # For now, setting this is required.
        environment.darwinConfig = "${pkgs.lib.hacknix.path}/examples/nix-darwin/remote-builder.nix";

        nix.maxJobs = 12;

        # Disable Nix flakes for remote builders, as stable Nix is
        # more reliable with Hercules CI and Hydra.
        hacknix-nix-darwin.defaults.nix.enable = lib.mkForce false;

        hacknix-nix-darwin.remote-build-host = {
          enable = true;
          user.sshPublicKeys = lib.singleton sshPublicKey;
        };
      });
}
