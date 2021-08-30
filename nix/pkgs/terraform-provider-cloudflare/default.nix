{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-cloudflare";
  version = "2.26.1";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "terraform-provider-cloudflare";
    rev = "v${version}";
    sha256 = "sha256-7j7ZufKa+nGoN4izZ0Dl8SPFfPCI/2gITBnaOfB1Q6k=";
  };

  vendorSha256 = "sha256-8ia/4hLdbWSxel+CF4pkWiK7LlA95w3hSc9k3AH9hCU=";

  postInstall = "mv $out/bin/terraform-provider-cloudflare{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for Cloudflare";
    homepage = "https://github.com/cloudflare/terraform-provider-cloudflare";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
