{ lib, stdenv, python2Packages }:

python2Packages.buildPythonApplication rec {
  pname = "trimpcap";
  version = "1.3";

  src = ./.;

  pythonPath = with python2Packages; [ dpkt repoze_lru ];
  nativeBuildInputs = with python2Packages; [ wrapPython ];

  doBuild = false;

  installPhase = ''
    mkdir -p $out/bin
    cp trimpcap.py $out/bin/trimpcap
    chmod 0555 $out/bin/trimpcap
    wrapPythonPrograms
  '';

  meta = with lib; {
    homepage = "https://www.netresec.com/?page=TrimPCAP";
    description = "Trim pcap files";
    license = licenses.gpl2;
    maintainers = maintainers.dhess;
    platforms = platforms.all;
  };
}
