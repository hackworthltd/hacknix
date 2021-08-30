{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-postgresql";
  version = "1.14.0";

  src = fetchFromGitHub {
    owner = "cyrilgdn";
    repo = "terraform-provider-postgresql";
    rev = "v${version}";
    sha256 = "sha256-2VDPKpBedX0Q6xWwUL/2afGvtvlRSQhK+wdXTLyI6CM=";
  };

  vendorSha256 = null;

  postInstall = "mv $out/bin/terraform-provider-postgresql{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for PostgreSQL";
    homepage = "https://github.com/go-gandi/terraform-provider-postgresql";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
