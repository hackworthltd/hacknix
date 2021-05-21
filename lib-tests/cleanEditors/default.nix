## checkPhase will fail unless you cleanSourceEditors

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

  name = "dln-cleanEditors-test-${version}";

  doCheck = true;
  checkPhase = ''
    ${testLib.test-no-file "." ".dir-locals.el"}
    ${testLib.test-no-file "." ".netrwhist"}
    ${testLib.test-no-file "." ".projectile"}
    ${testLib.test-no-file "." ".tags"}
    ${testLib.test-no-file "." ".vim.custom"}
    ${testLib.test-no-file "." ".vscodeignore"}
    ${testLib.test-no-file "." ".#*"}
    ${testLib.test-no-file "." "*_flymake.*"}
    ${testLib.test-no-file "." "flycheck_*.el"}
  '';

  installPhase = ''
    mkdir $out
    cp -rp . $out
  '';

  meta.platforms = pkgs.lib.platforms.all;
}
