{ mkDerivation, base, bytestring, Cabal, directory, fetchgit
, filepath, process, stdenv, xhtml, xml
}:
mkDerivation {
  pname = "haddock-test";
  version = "0.0.1";
  src = fetchgit {
    url = "https://github.com/haskell/haddock.git";
    sha256 = "0b6c78paq6hh8n9pasnwwmlhfk745ha84fd84500mcpjlrsm5qgf";
    rev = "be8b02c4e3cffe7d45b3dad0a0f071d35a274d65";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/haddock-test; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base bytestring Cabal directory filepath process xhtml xml
  ];
  homepage = "http://www.haskell.org/haddock/";
  description = "Test utilities for Haddock";
  license = stdenv.lib.licenses.bsd3;
}
