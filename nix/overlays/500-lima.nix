final: prev:
let
  lima = final.callPackage ../pkgs/lima { };
in
{
  inherit lima;
}
