{ mkDerivation, alex, array, base, base-compat, containers, dlist
, fetchgit, filepath, happy, monadLib, pretty, stdenv
, template-haskell, text, th-abstraction, th-lift
}:
mkDerivation {
  pname = "ivory";
  version = "0.1.0.10";
  src = fetchgit {
    url = "https://github.com/GaloisInc/ivory.git";
    sha256 = "01bf3cjy7g8xz2ggrka8qgkbjphyjrl1qzjc2mfr7400zyvcnapy";
    rev = "53a0795b4fbeb0b7da0f6cdaccdde18849a78cd6";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/ivory; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    array base base-compat containers dlist filepath monadLib pretty
    template-haskell text th-abstraction th-lift
  ];
  libraryToolDepends = [ alex happy ];
  homepage = "http://ivorylang.org";
  description = "Safe embedded C programming";
  license = stdenv.lib.licenses.bsd3;
}
