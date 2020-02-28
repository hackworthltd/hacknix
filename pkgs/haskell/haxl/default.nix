{ mkDerivation, aeson, base, binary, bytestring, containers
, deepseq, exceptions, fetchgit, filepath, ghc-prim, hashable
, hashtables, HUnit, pretty, stdenv, stm, test-framework
, test-framework-hunit, text, time, transformers
, unordered-containers, vector
}:
mkDerivation {
  pname = "haxl";
  version = "2.3.0.0";
  src = fetchgit {
    url = "https://github.com/facebook/Haxl.git";
    sha256 = "1b0xl21svymljwd9ggrgmjkjsflpvi220a1xwfj7d9nndndm1i1r";
    rev = "0e28550cb41dc82e788d1c34159a48cd60440472";
    fetchSubmodules = true;
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson base binary bytestring containers deepseq exceptions filepath
    ghc-prim hashable hashtables pretty stm text time transformers
    unordered-containers vector
  ];
  testHaskellDepends = [
    aeson base binary bytestring containers deepseq filepath hashable
    hashtables HUnit test-framework test-framework-hunit text time
    unordered-containers
  ];
  homepage = "https://github.com/facebook/Haxl";
  description = "A Haskell library for efficient, concurrent, and concise data access";
  license = stdenv.lib.licenses.bsd3;
}
