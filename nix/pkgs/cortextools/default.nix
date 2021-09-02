{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "cortextools";
  version = "0.10.3";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "cortex-tools";
    rev = "v${version}";
    sha256 = "sha256-h71/xjCnU31EpnN0j6PjrZn+GIlQsFCoKMivHXPMwwU=";
  };

  vendorSha256 = null;

  doCheck = true;

  meta = with lib; {
    description = "Tools used for interacting with Cortex.";
    homepage = "https://github.com/grafana/cortex-tools";
    license = licenses.asl20;
    maintainers = with maintainers; [ dhess ];
  };
}
