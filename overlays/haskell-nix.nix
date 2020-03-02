## haskell.nix support.
#
# Note that this overlay is done a bit differently and is really
# intended to be a separate package set, rather than seamlessly
# integrated into our own overlay/package set, because for the most
# part, we don't want to use the haskell.nix overlay in our own
# overlay; we just want the Haskell build support.

self: super:

let

  localLib = import ../lib;

  haskellNix = import localLib.fixedHaskellNix;

  # This haskell.nix nixpkgs should be constructed as closely as
  # possible to how we do it in our haskell.nix-based Haskell
  # projects, for maximal caching.
  haskell-nix-nixpkgs = localLib.nixpkgs {
    inherit (haskellNix) config;
    overlays = localLib.overlays ++ haskellNix.overlays;
  };

  haskell-nix = {
    ghc883 = haskell-nix-nixpkgs.haskell-nix.compiler.ghc883;
  };

in
{
  inherit haskell-nix;
}
