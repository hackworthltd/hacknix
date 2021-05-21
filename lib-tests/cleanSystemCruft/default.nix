## checkPhase will fail unless you cleanSourceSystemCruft.

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

  name = "dln-cleanSystemCruft-test-${version}";

  doCheck = true;
  checkPhase = ''
    ${testLib.test-no-file "." ".DS_Store"}
  '';

  installPhase = ''
    mkdir $out
    cp -rp . $out
  '';

  meta.platforms = pkgs.lib.platforms.all;
}
