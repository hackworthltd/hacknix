{ mkDerivation, base, bytestring, case-insensitive, containers
, fetchgit, QuickCheck, stdenv, tasty, tasty-quickcheck
, utf8-string
}:
mkDerivation {
  pname = "http-media";
  version = "0.8.0.0";
  src = fetchgit {
    url = "https://github.com/zmthy/http-media.git";
    sha256 = "0rayyf7kbzfn6nhx2fizspwivs6f6m1prhxzlc9wm8xgnrbw9vws";
    rev = "95bddbe3ccb969685df9225c73cff0dc1baaae69";
    fetchSubmodules = true;
  };
  libraryHaskellDepends = [
    base bytestring case-insensitive containers utf8-string
  ];
  testHaskellDepends = [
    base bytestring case-insensitive containers QuickCheck tasty
    tasty-quickcheck utf8-string
  ];
  homepage = "https://github.com/zmthy/http-media";
  description = "Processing HTTP Content-Type and Accept headers";
  license = stdenv.lib.licenses.mit;
}
