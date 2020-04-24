{ config, pkgs, lib, ... }:

let

  localLib = import ../../lib;

in {
  # For now, setting this is required.
  environment.darwinConfig = "${localLib.path}/examples/remote-builder.nix";

  imports = localLib.nixDarwinModules;
  nix.maxJobs = 12;
  hacknix-nix-darwin.remote-build-host = {
    enable = true;
    user.sshPublicKeyFiles = lib.singleton ./remote-builder.pub;
  };
}
