## checkPhase will fail unless you cleanSourceAllExtraneous

{ stdenv
, pkgs
, src
}:
let
  version = "1";
  testLib = import ../lib.nix;
in
stdenv.mkDerivation rec {
  inherit src;

  name = "dln-cleanAllExtraneous-test-${version}";

  doCheck = true;
  checkPhase = ''
    # Nix.
    ${testLib.test-dir "." "nix"}
    ${testLib.test-no-file "." "*.nix"}

    # Haskell.
    ${testLib.test-no-dir "." ".cabal-sandbox"}
    ${testLib.test-no-dir "." ".stack-work"}
    ${testLib.test-no-dir "." "dist"}
    ${testLib.test-no-dir "." "dist-newstyle"}

    ${testLib.test-no-file "." ".ghci"}
    ${testLib.test-no-file "." ".stylish-haskell.yaml"}
    ${testLib.test-no-file "." "cabal.sandbox.config"}

    # System cruft.
    ${testLib.test-no-file "." ".DS_Store"}

    # Editors.
    ${testLib.test-no-file "." ".dir-locals.el"}
    ${testLib.test-no-file "." ".netrwhist"}
    ${testLib.test-no-file "." ".projectile"}
    ${testLib.test-no-file "." ".tags"}
    ${testLib.test-no-file "." ".vim.custom"}
    ${testLib.test-no-file "." ".vscodeignore"}
    ${testLib.test-no-file "." ".#*"}
    ${testLib.test-no-file "." "*_flymake.*"}
    ${testLib.test-no-file "." "flycheck_*.el"}

    # Maintainer.
    ${testLib.test-no-file "." ".git"}
    ${testLib.test-no-file "." ".gitattributes"}
    ${testLib.test-no-file "." ".gitignore"}
    ${testLib.test-no-file "." ".gitmodules"}
    ${testLib.test-no-file "." ".npmignore"}
    ${testLib.test-no-file "." ".travis.yml"}
  '';

  installPhase = ''
    mkdir $out
    cp -rp . $out
  '';

  meta.platforms = pkgs.lib.platforms.all;
}
