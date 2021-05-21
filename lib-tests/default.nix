## An overlay which, when loaded, defines some self-testing packages.
## All you need to do is build these packages, and the tests will run
## in each package's checkPhase.

final: prev:
let
  inherit (prev) callPackage;
  inherit (final) lib;
  selfPath = ../.;
in
{

  ## cleanSourceX tests.

  dlnCleanSourceNix = callPackage ./cleanNix { src = lib.sources.cleanSourceNix ./test-dir; };
  dlnCleanSourceHaskell = callPackage ./cleanHaskell { src = lib.sources.cleanSourceHaskell ./test-dir; };
  dlnCleanSourceSystemCruft = callPackage ./cleanSystemCruft { src = lib.sources.cleanSourceSystemCruft ./test-dir; };
  dlnCleanSourceEditors = callPackage ./cleanEditors { src = lib.sources.cleanSourceEditors ./test-dir; };
  dlnCleanSourceMaintainer = callPackage ./cleanMaintainer { src = lib.sources.cleanSourceMaintainer ./test-dir; };
  dlnCleanSourceAllExtraneous = callPackage ./cleanAllExtraneous { src = lib.sources.cleanSourceAllExtraneous ./test-dir; };


  ## cleanPackage tests.

  dlnCleanPackageNix = lib.sources.cleanPackage lib.sources.cleanSourceNix (callPackage ./cleanNix { src = ./test-dir; });
  dlnCleanPackageHaskell = lib.sources.cleanPackage lib.sources.cleanSourceHaskell (callPackage ./cleanHaskell { src = ./test-dir; });
  dlnCleanPackageSystemCruft = lib.sources.cleanPackage lib.sources.cleanSourceSystemCruft (callPackage ./cleanSystemCruft { src = ./test-dir; });
  dlnCleanPackageEditors = lib.sources.cleanPackage lib.sources.cleanSourceEditors (callPackage ./cleanEditors { src = ./test-dir; });
  dlnCleanPackageMaintainer = lib.sources.cleanPackage lib.sources.cleanSourceMaintainer (callPackage ./cleanMaintainer { src = ./test-dir; });
  dlnCleanPackageAllExtraneous = lib.sources.cleanPackage lib.sources.cleanSourceAllExtraneous (callPackage ./cleanAllExtraneous { src = ./test-dir; });


  ## attrsets tests.

  dlnAttrSets = callPackage ./attrsets { inherit selfPath; };


  ## IP address utility tests.

  dlnIPAddr = callPackage ./ipaddr { inherit selfPath; };


  ## Miscellaneous tests.

  dlnMisc = callPackage ./misc { inherit selfPath; };


  ## Types tests.

  dlnTypes = callPackage ./types { inherit selfPath; };


  ## Security tests.

  dlnFfdhe = callPackage ./security/ffdhe { };
}
