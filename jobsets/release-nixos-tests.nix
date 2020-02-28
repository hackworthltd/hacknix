# This file is useful for testing from the command line, without
# needing to round-trip through Hydra:
#
# nix-build jobsets/release-tests.nix

let

  lib = import ../lib;
  localPkgs = (import ../.) {};

in

{ system ? "x86_64-linux"
, supportedSystems ? [ "x86_64-linux" ]
, scrubJobs ? true
, nixpkgsArgs ? {
    config = { allowUnfree = true; allowBroken = true; inHydra = true; };
    overlays = lib.singleton localPkgs.overlays.all;
  }
}:

let

in
  lib.collect
    lib.isDerivation
    (import ./release-nixos.nix { inherit system supportedSystems scrubJobs nixpkgsArgs; }).tests
