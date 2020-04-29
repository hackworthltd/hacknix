{ stdenv
, lib
, fetchFromGitHub
, Hypervisor
, vmnet
, SystemConfiguration
, xpc
, libobjc
, dtrace
}:

stdenv.mkDerivation rec {
  pname = "hyperkit";
  version = "0.20190802"; # keep in sync with src.rev

  src = fetchFromGitHub {
    owner = "moby";
    repo = "hyperkit";
    rev = "c0dd463fb4e406ad83275cdb57967e6c1974452e";
    sha256 = "1whli13clbm16d3mlahwhx893wq60mriz8h9k7r8dz8lw0kqgsyi";
  };

  buildInputs = [ Hypervisor vmnet SystemConfiguration xpc libobjc dtrace ];

  # 1. Don't use git to determine version
  # 2. Include dtrace probes
  prePatch = ''
    substituteInPlace Makefile \
      --replace 'shell git describe --abbrev=6 --dirty --always --tags' "v${version}" \
      --replace 'shell git rev-parse HEAD' "${src.rev}" \
      --replace 'PHONY: clean' 'PHONY:'
    make src/include/xhyve/dtrace.h
  '';

  makeFlags = [
    "CFLAGS+=-Wno-shift-sign-overflow"
    ''CFLAGS+=-DVERSION=\"v${version}\"''
    ''CFLAGS+=-DVERSION_SHA1=\"${src.rev}\"'' # required for vmnet
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp build/hyperkit $out/bin
  '';

  meta = with lib; {
    description =
      "A toolkit for embedding hypervisor capabilities in your application";
    homepage = "https://github.com/moby/hyperkit";
    maintainers = with maintainers; [ dhess ];
    platforms = platforms.darwin;
    license = licenses.bsd3;
  };
}
