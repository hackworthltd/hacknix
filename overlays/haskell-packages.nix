self: super:
let
  localLib = import ../lib;

  inherit (super) stdenv fetchpatch;
  inherit (super.haskell.lib)
    appendPatch doJailbreak dontCheck dontHaddock properExtend
    ;

  ## Useful functions.

  exeOnly = super.haskell.lib.justStaticExecutables;

  ## Haskell package fixes for various versions of GHC, based on the
  ## current nixpkgs snapshot that we're using.

  mkHaskellPackages = hp: properExtend hp (self: super: {});

  # The current GHC.
  haskellPackages = mkHaskellPackages super.haskellPackages;

  # cachix.
  mkCachixPackages = hp:
    properExtend hp (self: super: { cachix = (import localLib.fixedCachix); });

  cachix = exeOnly (mkCachixPackages haskellPackages).cachix;

  # Darcs won't build with GHC 8.8.x.
  mkDarcsPackages = hp:
    properExtend hp (
      self: super: {
        darcs = doJailbreak super.darcs;
        time-compat = doJailbreak super.time-compat;
      }
    );

  darcsHaskellPackages = mkDarcsPackages super.haskell.packages.ghc865;
  darcs = super.haskell.lib.overrideCabal
    (super.haskell.lib.justStaticExecutables darcsHaskellPackages.darcs) (
    drv: {
      configureFlags = (stdenv.lib.remove "-flibrary" drv.configureFlags or [])
      ++ [ "-f-library" ];
      hydraPlatforms = darcsHaskellPackages.ghc.meta.platforms;
      broken = false;
    }
  ) // {
    meta.platforms = darcsHaskellPackages.ghc.meta.platforms;
  };
in
{
  inherit haskellPackages;
  inherit cachix;
  inherit darcs;
}
