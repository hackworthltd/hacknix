final: prev:
let
  # Upstream keeps breaking this and it's usually not up-to-date, either.
  awscli2 = final.callPackage ../pkgs/awscli2 { };

  aws-sam-cli = final.callPackage ../pkgs/aws-sam-cli { };

in
{
  inherit awscli2 aws-sam-cli;
}
