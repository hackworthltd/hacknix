{ stdenv
, lib
, buildGoModule
, fetchFromGitHub
, Security
}:

buildGoModule rec {
  pname = "oauth2-proxy";
  version = "5.1.0";

  goPackagePath = "github.com/oauth2-proxy/${pname}";
  modSha256 = "09dn9s7ymh3mnbwsw4mk7grz08n3lamhp5rmy37k7fnqmv5rcx6a";

  src = fetchFromGitHub {
    repo = pname;
    owner = "oauth2-proxy";
    sha256 = "190k1v2c1f6vp9waqs01rlzm0jc3vrmsq1w1n0c2q2nfqx76y2wz";
    rev = "4cdedc8f50aeae16777c7852f35b8b16756012a7";
  };

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    description = "A reverse proxy that provides authentication with Google, Github or other provider";
    homepage = https://github.com/oauth2-proxy/oauth2-proxy/;
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
