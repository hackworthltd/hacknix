{ mkDerivation, array, base, bytestring, containers, deepseq
, directory, fetchgit, filepath, ghc, ghc-boot, ghc-paths
, haddock-library, hspec, hspec-discover, QuickCheck, stdenv
, transformers, xhtml
}:
mkDerivation {
  pname = "haddock-api";
  version = "2.23.0";
  src = fetchgit {
    url = "https://github.com/haskell/haddock.git";
    sha256 = "0b6c78paq6hh8n9pasnwwmlhfk745ha84fd84500mcpjlrsm5qgf";
    rev = "be8b02c4e3cffe7d45b3dad0a0f071d35a274d65";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/haddock-api; echo source root reset to $sourceRoot";
  enableSeparateDataOutput = true;
  libraryHaskellDepends = [
    array base bytestring containers deepseq directory filepath ghc
    ghc-boot ghc-paths haddock-library transformers xhtml
  ];
  testHaskellDepends = [
    array base bytestring containers deepseq directory filepath ghc
    ghc-boot ghc-paths haddock-library hspec QuickCheck transformers
    xhtml
  ];
  testToolDepends = [ hspec-discover ];
  homepage = "http://www.haskell.org/haddock/";
  description = "A documentation-generation tool for Haskell libraries";
  license = stdenv.lib.licenses.bsd3;
}
