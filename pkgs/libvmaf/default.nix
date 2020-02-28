{ stdenv, fetchFromGitHub, autoconf, automake, intltool, libtool, pkgconfig, lib }:

stdenv.mkDerivation rec {
  pname = "libvmaf";
  version = "1.3.15";

  src = fetchFromGitHub {
    owner = "netflix";
    repo = "vmaf";
    rev = "d4d48ddd8bdf39ec8e464d36d42e300c7336c061";
    sha256="0z4sn9ma0dmmikvarsi0zmy07pdv1qhp1c1kd68nlfbkk3v19pz1";
  };

  nativeBuildInputs = [ autoconf automake intltool libtool pkgconfig ];
  outputs = [ "out" "dev" ];
  doCheck = true;

  patchPhase = stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace src/ptools/Makefile.VMAF \
      --replace "CC = g++" "CC = clang++"
  '';

  postFixup = ''
    substituteInPlace "$dev/lib/pkgconfig/libvmaf.pc"     \
      --replace "includedir=/usr/local" "includedir=$dev" \
      --replace "prefix=/usr/local" "prefix=$out"         \
      --replace "libdir=/usr/local" "libdir=$out"
  '';

  makeFlags = [ "INSTALL_PREFIX=${placeholder "out"}" ];

  meta = with lib; {
    homepage = "https://github.com/Netflix/vmaf";
    description = "Perceptual video quality assessment based on multi-method fusion (VMAF)";
    platforms = platforms.all;
    license = licenses.asl20;
    maintainers = [ maintainers.dhess ];
  };

}
