{ projectSrc ? {
    outPath = ./.;
    rev = "abcdef";
  }
, config ? {
    allowUnfree = true;
    allowBroken = true;
    inHydra = true;
  }
, supportedSystems ? [ "x86_64-darwin" "x86_64-linux" ]
, scrubJobs ? true
, sourcesOverride ? { }
}:
let
  localLib = import nix/default.nix { inherit sourcesOverride; };
in
with import (localLib.fixedNixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs;
  packageSet = import projectSrc;
  nixpkgsArgs = {
    inherit config;

    # Do not pass overlays here; if you do, release-lib.nix will try
    # to pass them to our project's default.nix, which doesn't take an
    # argument for that.
  };
};

# Notes:
#
# From this point onward, `pkgs` contains all the attributes defined
# in our project's top-level default.nix.
let
  nixos-tests = (
    import ./release-nixos.nix {
      inherit scrubJobs;
      supportedSystems = [ "x86_64-linux" ];
    }
  );
  x86_64 = [ "x86_64-linux" "x86_64-darwin" ];
  x86_64_linux = [ "x86_64-linux" ];
  linux = [ "x86_64-linux" ];
  jobs = { native = mapTestOn (packagePlatforms pkgs); };
in
jobs // nixos-tests
