{ mkDerivation, aeson, attoparsec, base, byteslice, bytesmith
, bytestring, criterion, deepseq, doctest, fetchgit, hashable
, hspec, hspec-discover, HUnit, natural-arithmetic, primitive
, QuickCheck, quickcheck-classes, random, small-bytearray-builder
, stdenv, tasty, tasty-hunit, tasty-quickcheck, text, text-short
, vector, wide-word
}:
mkDerivation {
  pname = "ip";
  version = "1.7.1";
  src = fetchgit {
    url = "https://github.com/andrewthad/haskell-ip.git";
    sha256 = "0zszgjy4chayjdpzmji1wad4fj3bh58snp9nkgslx6w04njbw61v";
    rev = "3380405540e1270a1027d1ab44a8906db08965c9";
    fetchSubmodules = true;
  };
  libraryHaskellDepends = [
    aeson attoparsec base byteslice bytesmith bytestring deepseq
    hashable natural-arithmetic primitive small-bytearray-builder text
    text-short vector wide-word
  ];
  testHaskellDepends = [
    attoparsec base byteslice bytestring doctest hspec HUnit QuickCheck
    quickcheck-classes tasty tasty-hunit tasty-quickcheck text
    text-short vector wide-word
  ];
  testToolDepends = [ hspec-discover ];
  benchmarkHaskellDepends = [
    attoparsec base byteslice bytestring criterion primitive random
    text
  ];
  homepage = "https://github.com/andrewthad/haskell-ip#readme";
  description = "Library for IP and MAC addresses";
  license = stdenv.lib.licenses.bsd3;
}
