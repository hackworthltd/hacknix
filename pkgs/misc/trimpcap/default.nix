{ lib
, stdenv
, makeWrapper
, python
, pythonPackages
}:

stdenv.mkDerivation rec {
  pname = "trimpcap";
  version = "1.1.1";
  name = "${pname}-${version}";

  src = ./.;

  buildInputs = [
    makeWrapper
    python
  ];

  propagatedBuildInputs = with pythonPackages; [ dpkt repoze_lru ];

  installPhase = ''
    mkdir -p $out/bin
    cp trimpcap.py $out/bin/trimpcap
    chmod 0555 $out/bin/trimpcap
    wrapProgram $out/bin/trimpcap --prefix PYTHONPATH : "$PYTHONPATH"
  '';

  meta = with lib; {
    homepage = https://www.netresec.com/?page=TrimPCAP;
    description = "Trim pcap files";
    license = licenses.gpl2;
    maintainers = maintainers.dhess;
    platforms = platforms.all;
  };
}
