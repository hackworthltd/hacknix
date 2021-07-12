{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-postgresql";
  version = "1.13.0";

  src = fetchFromGitHub {
    owner = "cyrilgdn";
    repo = "terraform-provider-postgresql";
    rev = "v${version}";
    sha256 = "13zadcwx1ji074l41c6bvnvggn63xhjlhs7gg156hiqq2vx0xyd2";
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
