{ mkDerivation, base, byte-order, byteslice, bytestring, contiguous
, gauge, primitive, run-st, stdenv, tasty, tasty-hunit
, tasty-quickcheck, text-short, wide-word
}:
mkDerivation {
  pname = "bytesmith";
  version = "0.3.1.0";
  sha256 = "0dc774228147526265ba2705b039a1a0154df692ec6409528cd0b0e7d3ea7cf2";
  revision = "1";
  editedCabalFile = "13maddwkl9ajczvnrsnsa9f7w20fzq8il09xh9lqhwyrz9yak4ii";
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
