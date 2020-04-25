{ stdenv, lib, buildGoModule, fetchFromGitHub, Security }:

buildGoModule rec {
  pname = "traefik-forward-auth";
  version = "2.1.0";

  goPackagePath = "github.com/thomseddon/${pname}";
  modSha256 = "1618j7lydmrjd3d8bfcbfadvadyc5g9pdpnp63xrxmgkizybvz64";

  src = fetchFromGitHub {
    repo = pname;
    owner = "thomseddon";
    sha256 = "1m9gv6z3cvqy7acp0f33hnkas4cjlr0wih60kz4yxc0j44iar9mv";
    rev = "9abf5645b76e9a1fa18feb2e598ed0ab99082665";
  };

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    description =
      "An OAuth/OIDC forward authentication service for the traefik reverse proxy.";
    homepage = "https://github.com/oauth2-proxy/oauth2-proxy/";
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
