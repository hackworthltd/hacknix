{ stdenv, lib, buildGoModule, fetchFromGitHub, Security }:

buildGoModule rec {
  pname = "cfssl";
  version = "1.4.1";

  goPackagePath = "github.com/cloudflare/cfssl";
  deleteVendor = true;
  vendorSha256 = "0b9j94snxywajn56q8j7z5zmidcx8njc36vc5fydn93g34vk18wy";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cfssl";
    rev = "v${version}";
    sha256 = "07qacg95mbh94fv64y577zyr4vk986syf8h5l8lbcmpr0zcfk0pd";
  };

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    homepage = "https://cfssl.org/";
    description = "Cloudflare's PKI and TLS toolkit";
    license = licenses.bsd2;
    maintainers = lib.singleton lib.maintainers.dhess;
    platforms = platforms.all;
  };
}
