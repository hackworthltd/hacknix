final: prev:
let
  tsoff = prev.callPackage ../pkgs/tsoff { };
in
{
  inherit tsoff;
}
