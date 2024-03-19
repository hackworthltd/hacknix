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
  ## attrsets tests.

  dlnAttrSets = callPackage ./attrsets { inherit selfPath; };


  ## IP address utility tests.

  dlnIPAddr = callPackage ./ipaddr { inherit selfPath; };


  ## Miscellaneous tests.

  dlnMisc = callPackage ./misc { inherit selfPath; };


  ## Types tests.

  dlnTypes = callPackage ./types { inherit selfPath; };
}
