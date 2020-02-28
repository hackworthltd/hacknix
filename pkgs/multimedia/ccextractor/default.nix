{ stdenv
, lib
, libiconv
, fetchgit
, cmake
, pkgconfig
, tesseract
, leptonica
, ffmpeg
, zlib
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name    = "ccextractor-${version}";
  version = "0.87";

  src = fetchgit {
    url    = "https://github.com/CCExtractor/ccextractor.git";
    rev    = "17a6779146be813c5d99ec9b0b53e345fcd9a74f";
    sha256 = "03fhpr78kxi3h68agc65hn8v053c3016bcgrx3kb5sp29c8kbfgk";
  };

  nativeBuildInputs = [ cmake pkgconfig ];

  buildInputs = [
    tesseract leptonica ffmpeg libiconv zlib
  ];

  cmakeFlags = [
    "-DWITH_FFMPEG=ON"
    "-DWITH_OCR=ON"
    "-DWITH_HARDSUBX=ON"
    "../src"
  ];

  meta = {
    description = "Extract independent subtitle files from video files";
    homepage    = https://www.ccextractor.org;
    license     = licenses.gpl2;
    platforms   = platforms.all;
    maintainers = lib.maintainers.dhess;
  };
}
