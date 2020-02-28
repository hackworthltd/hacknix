{ mkDerivation, base, byte-order, byteslice, bytestring, contiguous
, fetchgit, gauge, primitive, run-st, stdenv, tasty, tasty-hunit
, tasty-quickcheck, text-short, wide-word
}:
mkDerivation {
  pname = "bytesmith";
  version = "0.3.3.0";
  src = fetchgit {
    url = "https://github.com/andrewthad/bytesmith.git";
    sha256 = "1dbw9hpzriac4vf7jgnkfssm9m1y2sxs88rc04svxlsnfnhx90ym";
    rev = "a5800617498f6c861c2a95bbf5f03af8477b48df";
    fetchSubmodules = true;
  };
  libraryHaskellDepends = [
    base byteslice bytestring contiguous primitive run-st text-short
    wide-word
  ];
  testHaskellDepends = [
    base byte-order byteslice primitive tasty tasty-hunit
    tasty-quickcheck text-short wide-word
  ];
  benchmarkHaskellDepends = [
    base byteslice bytestring gauge primitive
  ];
  homepage = "https://github.com/andrewthad/bytesmith";
  description = "Nonresumable byte parser";
  license = stdenv.lib.licenses.bsd3;
}
