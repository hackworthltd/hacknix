{ stdenv
, lib
, buildGoModule
, Security
, src
}:

buildGoModule rec {
  pname = "traefik-forward-auth";
  version = "2.2.0";

  vendorSha256 = "031g9ldpnmwxhxgnbnzn5slxsy75mprzdwsk1svnpd3lsz8h29mr";
  inherit src;

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
