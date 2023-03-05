final: prev:
let
  lima-bin = final.callPackage ../pkgs/lima/bin.nix { };
  colima = final.callPackage ../pkgs/colima { };
in
{
  inherit lima-bin;
  inherit colima;
}
