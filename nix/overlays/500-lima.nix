final: prev:
let
  lima = final.callPackage ../pkgs/lima { };
  colima = final.callPackage ../pkgs/colima { };
in
{
  inherit lima;
  inherit colima;
}
