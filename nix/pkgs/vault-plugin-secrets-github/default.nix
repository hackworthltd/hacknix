{ lib
, git
, which
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "vault-plugin-secrets-github";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "martinbaillie";
    repo = "vault-plugin-secrets-github";
    rev = "v${version}";
    sha256 = "09i3prx4d0bc8g62gmvwbh02d1z209kynkckc465y5a5h21mqkjx";
  };

  vendorSha256 = "11ypzwnbaklcwmj5p84m647lal3mxnbswcby78bb0akq3935sl50";

  nativeBuildInputs = [
    which
    git
  ];

  preBuild = ''
    export buildFlagsArray=(
      -ldflags="$(make env-LDFLAGS)"
    )
  '';
  dontStrip = true;

  meta = with lib; {
    description = "A Vault secrets plugin for GitHub Apps.";
    homepage = "https://github.com/martinbaillie/vault-plugin-secrets-github";
    license = licenses.asl20;
    maintainers = [ maintainers.dhess ];
    platforms = platforms.linux;
  };
}
