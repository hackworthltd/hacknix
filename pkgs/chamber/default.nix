{ source, stdenv, lib, buildGoModule, fetchFromGitHub, Security }:
let
in
buildGoModule rec {
  pname = "chamber";
  version = "2.8.0";

  goPackagePath = "github.com/${source.owner}/${source.repo}";
  vendorSha256 = "0l9wjvlkkqyjjh949av041iwxsni4d3ypp2kf9iqfpi9l7kwf3nn";

  src = fetchFromGitHub { inherit (source) repo owner sha256 rev; };

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    description = source.description;
    homepage = "https://github.com/segmentio/chamber/";
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
