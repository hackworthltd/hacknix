{ mkDerivation, aeson, base, bytestring, bytestring-trie
, cabal-helper, constrained-dynamic, containers, cryptohash-sha1
, data-default, Diff, directory, fetchgit, filepath, fingertree
, free, ghc, haskell-lsp, hie-bios, hslogger, monad-control, mtl
, process, sorted-list, stdenv, stm, syb, text, transformers
, transformers-base, unix, unliftio, unliftio-core
, unordered-containers, yaml
}:
mkDerivation {
  pname = "hie-plugin-api";
  version = "1.2";
  src = fetchgit {
    url = "https://github.com/haskell/haskell-ide-engine.git";
    sha256 = "1zhznf7fs56q2dl68rgzdsfgf3mhyw9gn027nasd9kghwa7hfl6n";
    rev = "35f62cffb6bae6c3f86113cb0c55f52b7192689d";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/hie-plugin-api; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    aeson base bytestring bytestring-trie cabal-helper
    constrained-dynamic containers cryptohash-sha1 data-default Diff
    directory filepath fingertree free ghc haskell-lsp hie-bios
    hslogger monad-control mtl process sorted-list stm syb text
    transformers transformers-base unix unliftio unliftio-core
    unordered-containers yaml
  ];
  description = "Haskell IDE API for plugin communication";
  license = stdenv.lib.licenses.bsd3;
}
