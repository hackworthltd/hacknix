## checkPhase will fail unless you cleanSourceNix.

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

  name = "dln-cleanNix-test-${version}";

  doCheck = true;
  checkPhase = ''
    ${testLib.test-dir "." "nix"}
    ${testLib.test-no-file "." "*.nix"}
    ${testLib.test-no-file "." "result*"}
  '';

  installPhase = ''
    mkdir $out
    cp -rp . $out
  '';

  meta.platforms = pkgs.lib.platforms.all;
}
