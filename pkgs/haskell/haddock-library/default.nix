{ mkDerivation, base, base-compat, bytestring, containers, deepseq
, directory, fetchgit, filepath, hspec, hspec-discover
, optparse-applicative, parsec, QuickCheck, stdenv, text
, transformers, tree-diff
}:
mkDerivation {
  pname = "haddock-library";
  version = "1.8.0.1";
  src = fetchgit {
    url = "https://github.com/haskell/haddock.git";
    sha256 = "0b6c78paq6hh8n9pasnwwmlhfk745ha84fd84500mcpjlrsm5qgf";
    rev = "be8b02c4e3cffe7d45b3dad0a0f071d35a274d65";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/haddock-library; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base bytestring containers parsec text transformers
  ];
  testHaskellDepends = [
    base base-compat bytestring containers deepseq directory filepath
    hspec optparse-applicative parsec QuickCheck text transformers
    tree-diff
  ];
  testToolDepends = [ hspec-discover ];
  homepage = "http://www.haskell.org/haddock/";
  description = "Library exposing some functionality of Haddock";
  license = stdenv.lib.licenses.bsd2;
}
