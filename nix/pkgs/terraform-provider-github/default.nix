{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-github";
  version = "4.12.1";

  src = fetchFromGitHub {
    owner = "integrations";
    repo = "terraform-provider-github";
    rev = "v${version}";
    sha256 = "1l9lh1hq8kbz0399mhcnx86h07n11x0d82pkg5n2drx3j1mf6wqa";
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
