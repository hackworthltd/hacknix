{ source, stdenv, lib, buildGoModule, fetchFromGitHub, Security }:
let
in
buildGoModule rec {
  pname = "chamber";
  version = "2.8.2";

  goPackagePath = "github.com/${source.owner}/${source.repo}";
  vendorSha256 = "01h6mbv6s9qz613b1699mmqxy9204szli90axg1rh9l4pd2sjlm2";

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
