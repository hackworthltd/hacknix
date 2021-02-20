final: prev:
let
  # Upstream keeps breaking this and it's usually not up-to-date, either.
  awscli2 = final.callPackage ../pkgs/awscli2 { };
in
{
  inherit awscli2;
}
