final: prev:
let
  aws-sam-cli = final.callPackage ../pkgs/aws-sam-cli { };

in
{
  inherit aws-sam-cli;
}
