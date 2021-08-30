{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-github";
  version = "4.13.0";

  src = fetchFromGitHub {
    owner = "integrations";
    repo = "terraform-provider-github";
    rev = "v${version}";
    sha256 = "sha256-ERGvowpkYZyIeq8gxDF5X1BvEPL1jLYXWA6m9gVNFRk=";
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
