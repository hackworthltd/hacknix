final: prev:
let
  vector = final.callPackage ../pkgs/vector {
  };
in
{
  inherit vector;
}
