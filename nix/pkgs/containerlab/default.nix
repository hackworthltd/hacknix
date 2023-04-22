# From:
# https://github.com/NixOS/nixpkgs/pull/196282

{ lib, fetchFromGitHub, buildGoModule }:

let
  version = "0.39.0";
in
buildGoModule {
  pname = "containerlab";
  inherit version;

  src = fetchFromGitHub {
    owner = "srl-labs";
    repo = "containerlab";
    rev = "v${version}";
    sha256 = "sha256-tfk0G3Pl9RJqY9W6KPjThqjus9lJYDBDPSS/jW7dMjg=";
  };

  vendorSha256 = "sha256-AOpIVNGMS4ApRJN//d3H1tpCY8wlldONHJZIoCk72Vw=";

  ldFlags = [
    "-s"
    "-w"
    "-X github.com/srl-labs/containerlab/cmd.version=${version}"
    "-X github.com/srl-labs/containerlab/cmd.commit=${version}"
    "-X github.com/srl-labs/containerlab/cmd.date=1970-01-01T00:00:00"
  ];

  meta = with lib; {
    description = "containerlab enables container-based networking labs";
    homepage = "https://github.com/srl-labs/containerlab";
    license = licenses.bsd3;
    maintainers = with maintainers; [ dhess ];
    platforms = platforms.linux;
  };
}
