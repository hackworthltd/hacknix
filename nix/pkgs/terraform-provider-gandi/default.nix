{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-gandi";
  # Note: this cannot include the -rc3 suffix or else Terraform can't parse it.
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "go-gandi";
    repo = "terraform-provider-gandi";
    rev = "v${version}-rc3";
    sha256 = "sha256-2BUFDkKATg9JncPzZ0Xf3MgQM8NZzdSDrxoMEKXBEx0=";
  };

  vendorSha256 = "sha256-bJ3LMcAndsahshpz7fT/F3MstVC+aPfBzYuBaWUNS1g=";

  postInstall = "mv $out/bin/terraform-provider-gandi{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for Gandi.net";
    homepage = "https://github.com/go-gandi/terraform-provider-gandi";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
