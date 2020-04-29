{ stdenv
, lib
, fetchurl
, pkgconfig
, bison
, flex
, gawk
, gnutls
, lua
, perl
, python
, ruby
, swig
}:

stdenv.mkDerivation rec {
  name = "libprelude-${version}";
  version = "5.0.0";

  src = fetchurl {
    url =
      "https://www.prelude-siem.org/attachments/download/1025/libprelude-5.0.0.tar.gz";
    sha256 = "12n4ai46l88qgm9xrz8k23nkygk9nyrczy8jk8bmkq9jksjvr58g";
  };

  nativeBuildInputs = [ bison flex gawk pkgconfig swig ];

  buildInputs = [ gnutls ];

  propagatedBuildInputs = [ lua perl python ruby ];

  enableParallelBuilding = true;

  configureFlags = [ "--localstatedir=/var" "--sysconfdir=/etc" ];

  installFlags = [
    "PRELUDE_SPOOL_DIR=\${TMPDIR}"
    "PRELUDE_CONFIG_DIR=\${out}/etc"
    "localstatedir=\${TMPDIR}"
    "sysconfdir=\${out}/etc"
  ];

  meta = with lib; {
    homepage = "https://www.prelude-siem.org/projects/libprelude";
    description = "IDMEF transport library used by all Prelude agents";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    maintainers = [ maintainers.dhess ];
  };
}
