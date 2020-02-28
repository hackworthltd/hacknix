{ stdenv
, lib
, fetchFromGitHub
, pkgconfig
, libpcap
, libnl
}:

stdenv.mkDerivation rec {
  name = "nmrpflash";
  version = "0.9.14";

  src = fetchFromGitHub {
    repo = name;
    owner = "jclehner";
    sha256 = "1fdjrxhjs96rdclbkld57xarf592slhkp79h46z833npxpn12ck1";
    rev = "v${version}";
  };

  patches = [
    ./Makefile.patch
  ];

  nativeBuildInputs = stdenv.lib.optionals stdenv.isLinux [
    pkgconfig
  ];

  buildInputs = [ libpcap ] ++ stdenv.lib.optionals stdenv.isLinux [
    libnl
  ];

  configurePhase = stdenv.lib.optionalString stdenv.isLinux ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE $(pkg-config --cflags libnl-route-3.0)"
    export NIX_CFLAGS_LINK="$NIX_CFLAGS_LINK $(pkg-config --libs libnl-route-3.0)"
  '';

  buildFlags = "PREFIX=$(out) VERSION=${version}";
  installFlags = buildFlags;

  meta = with lib; {
    homepage = https://github.com/jclehner/nmrpflash;
    description = "A Netgear unbrick utility";
    platforms = platforms.unix;
    maintainers = with maintainers; [ dhess ];
  };
}
