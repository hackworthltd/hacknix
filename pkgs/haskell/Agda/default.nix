{ mkDerivation, aeson, alex, array, async, base, binary, blaze-html
, boxes, bytestring, Cabal, containers, data-hash, deepseq
, directory, edit-distance, emacs, equivalence, exceptions
, fetchgit, filemanip, filepath, geniplate-mirror, ghc-compact
, gitrev, happy, hashable, hashtables, haskeline, ieee754, mtl
, murmur-hash, pretty, process, process-extras, QuickCheck
, regex-tdfa, split, stdenv, stm, strict, tasty, tasty-hunit
, tasty-quickcheck, tasty-silver, template-haskell, temporary, text
, time, transformers, unix-compat, unordered-containers, uri-encode
, zlib
}:
mkDerivation {
  pname = "Agda";
  version = "2.6.1";
  src = fetchgit {
    url = "https://github.com/agda/agda.git";
    sha256 = "0ywpvphbnwjqrx4vpz3cvhin4awvy93ipi8d6sfa2sqlnr5li1jj";
    rev = "f275daf2443ac348c287e08cb53ffec7db59625d";
    fetchSubmodules = true;
  };
  isLibrary = true;
  isExecutable = true;
  enableSeparateDataOutput = true;
  setupHaskellDepends = [ base Cabal directory filepath process ];
  libraryHaskellDepends = [
    aeson array async base binary blaze-html boxes bytestring
    containers data-hash deepseq directory edit-distance equivalence
    exceptions filepath geniplate-mirror ghc-compact gitrev hashable
    hashtables haskeline ieee754 mtl murmur-hash pretty process
    regex-tdfa split stm strict template-haskell text time transformers
    unordered-containers uri-encode zlib
  ];
  libraryToolDepends = [ alex happy ];
  executableHaskellDepends = [ base directory filepath process ];
  executableToolDepends = [ emacs ];
  testHaskellDepends = [
    array base bytestring containers directory filemanip filepath mtl
    process process-extras QuickCheck regex-tdfa tasty tasty-hunit
    tasty-quickcheck tasty-silver temporary text unix-compat uri-encode
  ];
  postInstall = ''
    files=("$data/share/ghc-"*"/"*"-ghc-"*"/Agda-"*"/lib/prim/Agda/"{Primitive.agda,Builtin"/"*.agda})
    for f in "''${files[@]}" ; do
      $out/bin/agda $f
    done
    for f in "''${files[@]}" ; do
      $out/bin/agda -c --no-main $f
    done
    $out/bin/agda-mode compile
  '';
  homepage = "http://wiki.portal.chalmers.se/agda/";
  description = "A dependently typed functional programming language and proof assistant";
  license = "unknown";
  hydraPlatforms = stdenv.lib.platforms.none;
}
