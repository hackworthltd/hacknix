{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-keycloak";
  version = "3.3.0";

  src = fetchFromGitHub {
    owner = "mrparkers";
    repo = "terraform-provider-keycloak";
    rev = "v${version}";
    sha256 = "sha256-FcCLQVRpiM6oLUYJxc4Cn/0aXYkM1wPQfr1qLPd6r1o=";
  };

  vendorSha256 = "sha256-oPLZsxAXXf9TGQY+qeAYG37Oioqfqeg0hIZ4afk2zz8=";

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
