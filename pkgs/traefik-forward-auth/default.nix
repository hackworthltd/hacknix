{ stdenv, lib, buildGoModule, fetchFromGitHub, Security }:

buildGoModule rec {
  pname = "traefik-forward-auth";
  version = "2.1.0";

  goPackagePath = "github.com/thomseddon/${pname}";
  vendorSha256 = "031g9ldpnmwxhxgnbnzn5slxsy75mprzdwsk1svnpd3lsz8h29mr";

  src = fetchFromGitHub {
    repo = pname;
    owner = "thomseddon";
    sha256 = "1m9gv6z3cvqy7acp0f33hnkas4cjlr0wih60kz4yxc0j44iar9mv";
    rev = "9abf5645b76e9a1fa18feb2e598ed0ab99082665";
  };

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [ Security ];

  postInstall = ''
    mv $out/bin/cmd $out/bin/traefik-forward-auth
  '';

  meta = with lib; {
    description =
      "An OAuth/OIDC forward authentication service for the traefik reverse proxy.";
    homepage = "https://github.com/thomseddon/traefik-forward-auth";
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
