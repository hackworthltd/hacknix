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
  version = "2.9.1";

  deleteVendor = true;
  vendorSha256 = "sha256-bXliUugkvS+dIo4BecvjjK7QSVFm90tNjcQFD8OJ2x8=";

  inherit src;

  buildInputs = lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    description = "A CLI for managing secrets in AWS.";
    homepage = "https://github.com/segmentio/chamber/";
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
