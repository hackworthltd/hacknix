{ stdenv
, lib
, buildGoModule
, fetchFromGitHub
, Security
, src
}:
let
in
buildGoModule rec {
  pname = "chamber";
  version = "2.8.2";

  deleteVendor = true;
  vendorSha256 = "05lipdkrr3v64ppj13gp48zfk0w946qfpavg6w2y591az4pyx7zl";

  inherit src;

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    description = "A CLI for managing secrets in AWS.";
    homepage = "https://github.com/segmentio/chamber/";
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
