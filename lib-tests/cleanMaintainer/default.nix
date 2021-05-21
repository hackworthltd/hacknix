## checkPhase will fail unless you cleanSourceMaintainer

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

  name = "dln-cleanMaintainer-test-${version}";

  doCheck = true;
  checkPhase = ''
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
