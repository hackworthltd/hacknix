{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-keycloak";
  version = "3.1.1";

  src = fetchFromGitHub {
    owner = "mrparkers";
    repo = "terraform-provider-keycloak";
    rev = "v${version}";
    sha256 = "0qh0y1j3y5hzcr8h8wzralv7h8dmrg8jnjccz0fzcmhbkazfrs4p";
  };

  vendorSha256 = "0il4rvwa23zghrq0b8qrzgxyjy0211v9z2a4ln2xmlhcz0105zg8";

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
