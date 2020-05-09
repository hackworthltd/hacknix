let
  sources = import ../nix/sources.nix;
  fixedHacknixLib =
    let
      try = builtins.tryEval <hacknix-lib>;
    in
    if try.success then
      builtins.trace "Using <hacknix-lib>" try.value
    else
      (import sources.hacknix-lib);
  hacknix-lib = fixedHacknixLib { };
  inherit (hacknix-lib) lib;
  inherit (lib.fetchers) fixedNixSrc;
  fixedNixpkgs = fixedNixSrc "nixpkgs_override" sources.nixpkgs-unstable;
  nixpkgs = import fixedNixpkgs;
  fixedNixDarwin = lib.fetchers.fixedNixSrc "nix_darwin" sources.nix-darwin;
  nix-darwin = (import fixedNixDarwin) { };
  fixedNixOps = lib.fetchers.fixedNixSrc "nixops" sources.nixops;
  fixedLorri = lib.fetchers.fixedNixSrc "lorri" sources.lorri;
  fixedBadhosts = lib.fetchers.fixedNixSrc "badhosts" sources.badhosts;
  fixedCachix = lib.fetchers.fixedNixSrc "cachix" sources.cachix;
  fixedGitignoreNix =
    lib.fetchers.fixedNixSrc "gitignore.nix" sources."gitignore.nix";
  overlays = [ hacknix-lib.overlays.all ] ++ (
    map import [
      ../overlays/custom-packages.nix
      ../overlays/emacs.nix
      ../overlays/haskell-packages.nix
      ../overlays/lib/hacknix.nix
      ../overlays/lib/types.nix
      ../overlays/overrides.nix
      ../overlays/patches.nix
      ../overlays/build-support.nix
      ../overlays/build-envs.nix
      ../overlays/examples.nix
    ]
  );

  # Provide access to the whole package, if needed.
  path = ../.;

  # A list of all the NixOS modules exported by this package.
  modulesList = ../modules/module-list.nix;

  # A list of all the nix-darwin modules exported by this package.
  nixDarwinModulesList = ../nix-darwin/module-list.nix;

  # All NixOS modules exported by this package. To use, add this
  # expression to your configuration's list of imports.
  modules = import modulesList;

  # All nix-darwin modules exported by this package. To use, add this
  # expression to your nix-darwin configuration's list of imports.
  nixDarwinModules = import nixDarwinModulesList;
in
lib // {
  inherit fixedNixpkgs;
  inherit fixedNixDarwin;
  inherit nixpkgs;
  inherit nix-darwin;
  inherit overlays;
  inherit fixedNixOps;
  inherit fixedLorri;
  inherit fixedBadhosts;
  inherit fixedCachix;
  inherit fixedGitignoreNix;

  inherit sources;

  inherit path;
  inherit modulesList modules;
  inherit nixDarwinModulesList nixDarwinModules;
}
