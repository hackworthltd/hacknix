{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-cloudflare";
  version = "2.23.0";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "terraform-provider-cloudflare";
    rev = "v${version}";
    sha256 = "0cyw6lddw3pj5lqra78qn0nd16ffay86vc8sqa68grx7ik9jgn7l";
  };

  vendorSha256 = "19fdwif81lqp848jhawd09b0lalslrwadd519vsdw03v2wp4p962";

  postInstall = "mv $out/bin/terraform-provider-cloudflare{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for Cloudflare";
    homepage = "https://github.com/cloudflare/terraform-provider-cloudflare";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
