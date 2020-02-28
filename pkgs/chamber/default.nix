{ lib
, buildGoModule
, fetchFromGitHub
}:

let

  localLib = import ../../lib;
  source = localLib.sources.chamber;

in
buildGoModule rec {
  pname = "chamber";
  version = "2.7.5";

  goPackagePath = "github.com/${source.owner}/${source.repo}";
  modSha256 = "0l9wjvlkkqyjjh949av041iwxsni4d3ypp2kf9iqfpi9l7kwf3nn";

  src = fetchFromGitHub {
    inherit (source) repo owner sha256 rev;
  };

  meta = with lib; {
    description = source.description;
    homepage = https://github.com/segmentio/chamber/;
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
