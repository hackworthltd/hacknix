self: super:
let
  localLib = import ../nix { };

  inherit (super) stdenv fetchpatch;
  inherit (super.haskell.lib)
    appendPatch doJailbreak dontCheck dontHaddock properExtend
    ;

  ## Useful functions.
  exeOnly = super.haskell.lib.justStaticExecutables;

  ## Haskell package fixes for various versions of GHC, based on the
  ## current nixpkgs snapshot that we're using.
  mkHaskellPackages = hp: properExtend hp (self: super: { });

  # The current GHC.
  haskellPackages = mkHaskellPackages super.haskellPackages;

  # cachix.
  mkCachixPackages = hp:
    properExtend hp (self: super: { cachix = (import localLib.fixedCachix); });
  cachix = exeOnly (mkCachixPackages haskellPackages).cachix;

in
{
  inherit haskellPackages;
  inherit cachix;
}
