{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "oauth2_proxy";
  version = "5.0.0";

  goPackagePath = "github.com/pusher/${pname}";
  modSha256 = "0zjmah0v8gkz4mn5z46yjz8zng6y397vbz6xm36p6z2p90n6s14n";

  src = fetchFromGitHub {
    repo = pname;
    owner = "pusher";
    sha256 = "0kd09pjcwxhb2dpscg0h7gca5klml4i3gm8ywq455kln9kpn1w2j";
    rev = "9670f54dd00fd75ffd0fb765f8fd60aa64c1fabd";
  };

  meta = with lib; {
    description = "A reverse proxy that provides authentication with Google, Github or other provider";
    homepage = https://github.com/pusher/oauth2_proxy/;
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.all;
  };
}
