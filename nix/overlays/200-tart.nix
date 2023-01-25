final: prev:
let
  tart = final.callPackage ../pkgs/tart { };
in
{
  inherit tart;
}
