{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-keycloak";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "mrparkers";
    repo = "terraform-provider-keycloak";
    rev = "v${version}";
    sha256 = "sha256-OmDZHh6H1UC34c52QxfHO9FXWSJd/BY/Zuo08KYan5I=";
  };

  vendorSha256 = "sha256-6P0CAvgM0tqFpUSJn3YIAnjp+/sZowVwhu8PofjOhEY=";

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
