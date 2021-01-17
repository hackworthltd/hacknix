{ config, pkgs, lib, ... }:
let
  localLib = import ../../nix { };
  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkRyutu3OMvSDFQOsOtls4A5krFlYEPbiPG/qUyxGdb example remote-builder key";

in
{
  # For now, setting this is required.
  environment.darwinConfig = "${localLib.path}/examples/remote-builder.nix";

  imports = localLib.nixDarwinModules;
  nix.maxJobs = 12;
  hacknix-nix-darwin.remote-build-host = {
    enable = true;
    user.sshPublicKeys = lib.singleton sshPublicKey;
  };
}
