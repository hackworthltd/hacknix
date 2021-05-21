{ lib
, git
, which
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "vault-plugin-secrets-github";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "martinbaillie";
    repo = "vault-plugin-secrets-github";
    rev = "v${version}";
    sha256 = "sha256-B4hN7k+39C8/Jung7hWaCgzIwW9WnCtku+6wfUSSytE=";
  };

  vendorSha256 = "sha256-pI5UN/FHw5hTFwXPQBmj+0DHhjQmv6QvWgi/sU5XoZE=";

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
