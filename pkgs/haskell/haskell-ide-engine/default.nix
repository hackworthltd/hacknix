{ mkDerivation, aeson, apply-refact, async, base, blaze-markup
, brittany, bytestring, bytestring-trie, Cabal, cabal-helper
, containers, data-default, Diff, directory, fetchgit, filepath
, floskell, fold-debounce, free, ghc, ghc-exactprint, gitrev
, haddock-api, haddock-library, haskell-lsp, haskell-lsp-types
, haskell-src-exts, hie-bios, hie-plugin-api, hlint, hoogle
, hsimport, hslogger, hspec, hspec-core, hspec-discover, lens
, lifted-async, lsp-test, monoid-subclasses, mtl
, optparse-applicative, optparse-simple, ormolu, parsec, process
, QuickCheck, quickcheck-instances, safe, sorted-list, stdenv, stm
, syb, tagsoup, text, transformers, unix-time, unliftio
, unordered-containers, vector, versions, yaml
}:
mkDerivation {
  pname = "haskell-ide-engine";
  version = "1.2";
  src = fetchgit {
    url = "https://github.com/haskell/haskell-ide-engine.git";
    sha256 = "1zhznf7fs56q2dl68rgzdsfgf3mhyw9gn027nasd9kghwa7hfl6n";
    rev = "35f62cffb6bae6c3f86113cb0c55f52b7192689d";
    fetchSubmodules = true;
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson apply-refact async base blaze-markup brittany bytestring
    bytestring-trie Cabal cabal-helper containers data-default Diff
    directory filepath floskell fold-debounce ghc ghc-exactprint gitrev
    haddock-api haddock-library haskell-lsp haskell-lsp-types
    haskell-src-exts hie-bios hie-plugin-api hlint hoogle hsimport
    hslogger hspec hspec-core lens lifted-async monoid-subclasses mtl
    optparse-simple ormolu parsec process safe sorted-list stm syb
    tagsoup text transformers unix-time unliftio unordered-containers
    vector versions yaml
  ];
  executableHaskellDepends = [
    base containers data-default directory filepath ghc haskell-lsp
    haskell-lsp-types hie-bios hie-plugin-api hslogger optparse-simple
    process stm text yaml
  ];
  testHaskellDepends = [
    aeson base bytestring cabal-helper containers data-default
    directory filepath free ghc haskell-lsp haskell-lsp-types hie-bios
    hie-plugin-api hoogle hspec lens lsp-test optparse-applicative
    process QuickCheck quickcheck-instances stm text
    unordered-containers
  ];
  testToolDepends = [ cabal-helper hspec-discover ];
  doHaddock = false;
  homepage = "http://github.com/githubuser/haskell-ide-engine#readme";
  description = "Provide a common engine to power any Haskell IDE";
  license = stdenv.lib.licenses.bsd3;
}
