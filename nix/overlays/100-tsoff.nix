final: prev:
let
  tsoff = final.callPackage ../pkgs/tsoff { };
in
{
  inherit tsoff;
}
