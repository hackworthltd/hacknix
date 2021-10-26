final: prev:
let
  colima = final.callPackage ../pkgs/colima { };
in
{
  inherit colima;
}
