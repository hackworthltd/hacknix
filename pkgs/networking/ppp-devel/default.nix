{ stdenv, fetchurl, fetchFromGitHub, substituteAll, libpcap, openssl }:

stdenv.mkDerivation rec {
  version = "2.4.7";
  name = "ppp-devel-${version}";

  src = fetchFromGitHub {
    owner = "paulusmack";
    repo = "ppp";
    rev = "5c765a67fd25f9d84e71ed61ace37c8c97f6be15";
    sha256 = "04i6zyvcn8dp6vg0lb9lyn96djaylvcqmzz3yvaazsja7z7v0w04";
  };

  patches =
    [ ( substituteAll {
        src = ./nix-purity.patch;
        inherit libpcap;
        glibc = stdenv.cc.libc.dev or stdenv.cc.libc;
      })
      # Without nonpriv.patch, pppd --version doesn't work when not run as
      # root.
      ./nonpriv.patch
      (fetchurl {
        name = "CVE-2015-3310.patch";
        url = "https://anonscm.debian.org/git/collab-maint/pkg-ppp.git/plain/debian/patches/rc_mksid-no-buffer-overflow?h=debian/2.4.7-1%2b4";
        sha256 = "1dk00j7bg9nfgskw39fagnwv1xgsmyv0xnkd6n1v5gy0psw0lvqh";
      })
      ./musl-fix-headers.patch
    ];

  buildInputs = [ libpcap openssl ];

  postPatch = ''
    # strip is not found when cross compiling with seemingly no way to point
    # make to the right place, fixup phase will correctly strip
    # everything anyway so we remove it from the Makefiles
    for file in $(find -name Makefile.linux); do
      substituteInPlace "$file" --replace '$(INSTALL) -s' '$(INSTALL)'
      substituteInPlace "$file" --replace "-I/usr/include/openssl" "-I${openssl.dev}/include/openssl"
      substituteInPlace "$file" --replace "4550" "555"
    done
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    make install
    install -D -m 755 scripts/{pon,poff,plog} $out/bin
    runHook postInstall
  '';

  postFixup = ''
    for tgt in pon poff plog; do
      substituteInPlace "$out/bin/$tgt" --replace "/usr/sbin" "$out/bin"
    done
  '';

  meta = with stdenv.lib; {
    homepage = https://ppp.samba.org/;
    description = "PPP daemon and associated utilities (development version)";
    license = with licenses; [ bsdOriginal publicDomain gpl2 lgpl2 ];
    platforms = platforms.linux;
  };
}
