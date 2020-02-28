{ stdenv
, lib
, makeWrapper
, pkgs
, perl
, perlPackages
, ethtool
}:

let

in
stdenv.mkDerivation rec {

  name = "tsoff";
  version = "1.0";
  src = ./.;

  buildInputs = [
    makeWrapper
    perl
    perlPackages.GetoptLong
    perlPackages.PodUsage
  ];

  installPhase = let path = stdenv.lib.makeBinPath [
    ethtool
  ]; in ''
    mkdir -p $out/bin
    cp tsoff $out/bin
    chmod 0755 $out/bin/tsoff
    wrapProgram $out/bin/tsoff --set PERL5LIB $PERL5LIB --prefix PATH : "${path}"
  '';

  meta = with lib; {
    description = "Disable offloading features on an Ethernet device";
    maintainers = maintainers.dhess;
    license = licenses.mit;
  };
}
