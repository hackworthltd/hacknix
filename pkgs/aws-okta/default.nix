{ stdenv, lib, source, buildGoModule, libiconv, libusb1, pkgconfig, Security }:

buildGoModule rec {
  pname = "aws-okta";
  version = source.version;

  goPackagePath = "github.com/segmentio/aws-okta";
  modSha256 = "01gk5nx1bxssm28gwdh9c311k2fcsp35bhrpfzwv4ln07nbzcwjq";

  src = source.outPath;

  buildFlags = "--tags release";

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ libusb1 libiconv ]
    ++ stdenv.lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    description = "aws-vault like tool for Okta authentication";
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
    homepage = "https://github.com/segmentio/aws-okta";
  };
}
