{ mkDerivation, aeson, async, base, base16-bytestring, binary
, bytestring, containers, cryptohash-sha1, data-default, deepseq
, directory, extra, fetchgit, filepath, fuzzy, ghc, ghc-boot
, ghc-boot-th, ghc-paths, ghc-typelits-knownnat, gitrev
, haddock-library, hashable, haskell-lsp, haskell-lsp-types
, hie-bios, hslogger, lens, lsp-test, mtl, network-uri
, optparse-applicative, parser-combinators, prettyprinter
, prettyprinter-ansi-terminal, QuickCheck, quickcheck-instances
, regex-tdfa, rope-utf16-splay, safe-exceptions, shake, sorted-list
, stdenv, stm, syb, tasty, tasty-expected-failure, tasty-hunit
, tasty-quickcheck, text, time, transformers, unix
, unordered-containers, utf8-string
}:
mkDerivation {
  pname = "ghcide";
  version = "0.1.0";
  src = fetchgit {
    url = "https://github.com/digital-asset/ghcide.git";
    sha256 = "0lqn3bc2hmkns2r2a8ss8jp31mi0x5bsh83kz78bk26792m0xlma";
    rev = "ff62fdd87de813573167419809273fe07893678d";
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
    base base16-bytestring binary bytestring containers cryptohash-sha1
    data-default deepseq directory extra filepath ghc ghc-paths gitrev
    hashable haskell-lsp hie-bios hslogger optparse-applicative shake
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
