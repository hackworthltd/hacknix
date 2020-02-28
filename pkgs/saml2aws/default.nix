{ stdenv
, lib  
, buildGoModule
, fetchFromGitHub }:

buildGoModule rec {
  pname = "saml2aws";
  version = "2.22.1";

  src = fetchFromGitHub {
    owner = "Versent";
    repo = "saml2aws";
    rev = "v${version}";
    sha256 = "1i06h7jv49vr3b778x1rln72i5jcyn62yxfi3h101i1l10hx9gl1";
  };

  modSha256 = "0qxf2i06spjig3ynixh3xmbxpghh222jhfqcg71i4i79x4ycp5wx";

  subPackages = [ "." "cmd/saml2aws" ];

  buildFlagsArray = ''
    -ldflags=-X main.Version=${version}
  '';

  meta = with lib; {
    description = "CLI tool which enables you to login and retrieve AWS temporary credentials using a SAML IDP";
    homepage    = "https://github.com/Versent/saml2aws";
    license     = licenses.mit;
    platforms   = platforms.unix;
    maintainers = [ maintainers.dhess ];
  };
}
