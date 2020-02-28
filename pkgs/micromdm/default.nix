{ buildGoModule
, fetchFromGitHub
, lib
, curl
, jq
, ngrok
}:

buildGoModule rec {
  pname = "micromdm";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "micromdm";
    repo = pname;
    #rev = "v${version}";
    rev = "ea5c0a3865e87f5de04a58dc2c67b5fa6f6fd7de";
    sha256 = "0cq8y2yhn28fnb0h4aacjnp76944hhdk376z6jbwih18k3xqhgrx";
  };

  modSha256 = "0dv0wj9vzjzlna3z02cqv5z8w5mzkabgrdnkkyl1yfpxls5g9y65";

  propagatedBuildInputs = [
    curl
    jq
    ngrok
  ];

  preConfigure = ''
    echo "Removing unused pkg/tools module..."
    rm -rf pkg/tools

    for dir in tools/ngrok tools/api tools/api/commands; do
      patchShebangs $dir
    done
  '';

  meta = with lib; {
    description = "A devops friendly MDM server.";
    homepage = "https://github.com/micromdm/micromdm";
    license = licenses.mit;
    maintainers = with lib.maintainers; [ dhess ];
  };

}
