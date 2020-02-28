{ mkDerivation, aeson, array, base, base16-bytestring, binary
, bytestring, comonad, containers, contravariant, criterion
, cryptohash-md5, cryptohash-sha1, cryptohash-sha256
, cryptohash-sha512, data-fix, deepseq, dependent-sum
, deriving-compat, Diff, directory, exceptions, fetchgit, filepath
, free, generic-random, Glob, hashable, hashing, haskeline
, hedgehog, hnix-store-core, http-client, http-client-tls
, http-types, interpolate, lens-family, lens-family-core
, lens-family-th, logict, megaparsec, monad-control, monadlist, mtl
, optparse-applicative, parser-combinators, pretty-show
, prettyprinter, process, ref-tf, regex-tdfa, repline, scientific
, semialign, semialign-indexed, semigroups, serialise, split
, stdenv, syb, tasty, tasty-hedgehog, tasty-hunit, tasty-quickcheck
, tasty-th, template-haskell, text, these, time, transformers
, transformers-base, unix, unordered-containers, vector, xml
}:
mkDerivation {
  pname = "hnix";
  version = "0.6.1";
  src = fetchgit {
    url = "https://github.com/haskell-nix/hnix";
    sha256 = "0b08m3l1mb39vx43bjmyydmm0s8q103afggmqavjdwpb2b9cqbwk";
    rev = "9b2ed1b244692511277bcd33ccbae20cf202b6d8";
    fetchSubmodules = false;
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson array base base16-bytestring binary bytestring comonad
    containers contravariant cryptohash-md5 cryptohash-sha1
    cryptohash-sha256 cryptohash-sha512 data-fix deepseq dependent-sum
    deriving-compat directory exceptions filepath free hashable hashing
    haskeline hnix-store-core http-client http-client-tls http-types
    interpolate lens-family lens-family-core lens-family-th logict
    megaparsec monad-control monadlist mtl optparse-applicative
    parser-combinators pretty-show prettyprinter process ref-tf
    regex-tdfa scientific semialign semialign-indexed semigroups
    serialise split syb template-haskell text these time transformers
    transformers-base unix unordered-containers vector xml
  ];
  executableHaskellDepends = [
    aeson base base16-bytestring bytestring comonad containers
    cryptohash-md5 cryptohash-sha1 cryptohash-sha256 cryptohash-sha512
    data-fix deepseq exceptions filepath free hashing haskeline mtl
    optparse-applicative pretty-show prettyprinter ref-tf repline
    serialise template-haskell text time transformers
    unordered-containers
  ];
  testHaskellDepends = [
    base base16-bytestring bytestring containers cryptohash-md5
    cryptohash-sha1 cryptohash-sha256 cryptohash-sha512 data-fix
    deepseq dependent-sum Diff directory exceptions filepath
    generic-random Glob hashing hedgehog interpolate megaparsec mtl
    optparse-applicative pretty-show prettyprinter process serialise
    split tasty tasty-hedgehog tasty-hunit tasty-quickcheck tasty-th
    template-haskell text time transformers unix unordered-containers
  ];
  benchmarkHaskellDepends = [
    base base16-bytestring bytestring containers criterion
    cryptohash-md5 cryptohash-sha1 cryptohash-sha256 cryptohash-sha512
    data-fix deepseq exceptions filepath hashing mtl
    optparse-applicative serialise template-haskell text time
    transformers unordered-containers
  ];
  homepage = "https://github.com/haskell-nix/hnix#readme";
  description = "Haskell implementation of the Nix language";
  license = stdenv.lib.licenses.bsd3;
}
