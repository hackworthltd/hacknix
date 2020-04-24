{ source, stdenv, lib, buildGoModule, fetchFromGitHub, libobjc, Foundation
, IOKit }:

buildGoModule rec {
  pname = "saml2aws";
  version = "2.25.0";

  src = fetchFromGitHub { inherit (source) repo owner sha256 rev; };

  modSha256 = "1kcj5065yy52p1jy4fad5lsz3y4spqc40k1qsirm53qqixhrhvag";

  subPackages = [ "." "cmd/saml2aws" ];

  buildInputs =
    stdenv.lib.optionals stdenv.isDarwin [ libobjc Foundation IOKit ];

  buildFlagsArray = ''
    -ldflags=-X main.Version=${version}
  '';

  meta = with lib; {
    description =
      "CLI tool which enables you to login and retrieve AWS temporary credentials using a SAML IDP";
    homepage = "https://github.com/Versent/saml2aws";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ maintainers.dhess ];
  };
}
