{ stdenv
, lib
, source
, fetchFromGitHub
, buildGoPackage
}:

buildGoPackage rec {
  name = "terraform-provider-vultr-${version}";
  version = source.version;

  goPackagePath = "github.com/${source.owner}/${source.repo}";

  src = source.outPath;

  # Terraform allow checking the provider versions, but this breaks
  # if the versions are not provided via file paths.
  postBuild = "mv go/bin/terraform-provider-vultr{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for Vultr.";
    homepage = "https://github.com/${source.owner}/${source.repo}";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}
