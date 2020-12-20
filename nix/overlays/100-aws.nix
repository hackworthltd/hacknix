final: prev:
let
  # Upstream keeps breaking this and it's usually not up-to-date, either.
  awscli2 = prev.callPackage ../pkgs/awscli2 { };

  aws-export-credentials = prev.callPackage ../pkgs/aws-export-credentials {
    src = prev.lib.hacknix.flake.inputs.aws-export-credentials;
  };

  aws-sso-credential-process = prev.callPackage ../pkgs/aws-sso-credential-process {
    src = prev.lib.hacknix.flake.inputs.aws-sso-credential-process;
  };

in
{
  inherit awscli2;
  inherit aws-export-credentials;
  inherit aws-sso-credential-process;
}
