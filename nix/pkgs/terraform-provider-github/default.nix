{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-github";
  version = "4.5.0";

  src = fetchFromGitHub {
    owner = "integrations";
    repo = "terraform-provider-github";
    rev = "v${version}";
    sha256 = "sha256-Zbhzf4FkpQdH7RFmGtaXz2dJ2c0Wh5Rneo57wp2j16A=";
  };

  vendorSha256 = null;

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-github{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for GitHub";
    homepage = "https://github.com/integrations/terraform-provider-github";
    license = licenses.mit;
    maintainers = with maintainers; [ dhess ];
  };
}
