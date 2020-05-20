{ lib
, poetry2nix
, src
}:

poetry2nix.mkPoetryApplication {
  inherit src;
  pyproject = ./pyproject.toml;
  poetrylock = ./poetry.lock;

  # Fails because of impurities (network, git etc etc)
  doCheck = false;

  meta = with lib; {
    description = "Bring AWS SSO-based credentials to the AWS SDKs until they have proper support";
    license = licenses.asl20;
    maintainers = with maintainers; [ dhess ];
    platforms = platforms.all;
    homepage = "https://github.com/benkehoe/aws-sso-credential-process";
  };
}
