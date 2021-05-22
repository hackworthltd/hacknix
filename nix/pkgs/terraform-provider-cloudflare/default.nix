{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-cloudflare";
  version = "2.20.0";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "terraform-provider-cloudflare";
    rev = "v${version}";
    sha256 = "sha256-J3KAf0PvngH9GNMY1uzlWxQwUyVYLiPIN8YSbuOVB8E=";
  };

  vendorSha256 = "sha256-sNEUJ60zJboMMlHOtVL3PeydT2mHhcygJzfP5cAyYCs=";

  postInstall = "mv $out/bin/terraform-provider-cloudflare{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for Cloudflare";
    homepage = "https://github.com/cloudflare/terraform-provider-cloudflare";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
