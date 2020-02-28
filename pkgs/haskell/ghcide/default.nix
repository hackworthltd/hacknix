{ mkDerivation, aeson, async, base, binary, bytestring, containers
, data-default, deepseq, directory, extra, fetchgit, filepath
, fuzzy, ghc, ghc-boot, ghc-boot-th, ghc-paths
, ghc-typelits-knownnat, gitrev, haddock-library, hashable
, haskell-lsp, haskell-lsp-types, hie-bios, hslogger, lens
, lsp-test, mtl, network-uri, optparse-applicative
, parser-combinators, prettyprinter, prettyprinter-ansi-terminal
, QuickCheck, quickcheck-instances, regex-tdfa, rope-utf16-splay
, safe-exceptions, shake, sorted-list, stdenv, stm, syb, tasty
, tasty-expected-failure, tasty-hunit, tasty-quickcheck, text, time
, transformers, unix, unordered-containers, utf8-string
}:
mkDerivation {
  pname = "ghcide";
  version = "0.1.0";
  src = fetchgit {
    url = "https://github.com/digital-asset/ghcide.git";
    sha256 = "1xf160grkgmh07hdl4b35laxpdz9r4aaaa5xxqh4kifn8vzl8ky3";
    rev = "2d71599faf5e93d4ee848043ddd68f10dd295260";
    fetchSubmodules = true;
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson async base binary bytestring containers data-default deepseq
    directory extra filepath fuzzy ghc ghc-boot ghc-boot-th
    haddock-library hashable haskell-lsp haskell-lsp-types hslogger mtl
    network-uri prettyprinter prettyprinter-ansi-terminal regex-tdfa
    rope-utf16-splay safe-exceptions shake sorted-list stm syb text
    time transformers unix unordered-containers utf8-string
  ];
  executableHaskellDepends = [
    base containers data-default directory extra filepath ghc ghc-paths
    gitrev haskell-lsp hie-bios hslogger optparse-applicative shake
    text unordered-containers
  ];
  testHaskellDepends = [
    aeson base bytestring containers directory extra filepath ghc
    ghc-typelits-knownnat haddock-library haskell-lsp haskell-lsp-types
    lens lsp-test parser-combinators QuickCheck quickcheck-instances
    rope-utf16-splay tasty tasty-expected-failure tasty-hunit
    tasty-quickcheck text
  ];
  homepage = "https://github.com/digital-asset/ghcide#readme";
  description = "The core of an IDE";
  license = stdenv.lib.licenses.asl20;
}
