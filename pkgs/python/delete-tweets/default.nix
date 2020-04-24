{ lib, python3 }:

python3.pkgs.buildPythonApplication rec {
  pname = "delete-tweets";
  version = "1.0.5";

  src = python3.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "0k2va244kvxrbmy1dkqhy5xvybm5vzl7a3698g8056bsdimm8w79";
  };

  pythonPath = with python3.pkgs; [ dateutil python-twitter ];

  meta = with lib; {
    homepage = "https://github.com/koenrh/delete-tweets";
    description = "Delete tweets from your timeline";
    license = licenses.isc;
    maintainers = with maintainers; [ dhess ];
  };
}
