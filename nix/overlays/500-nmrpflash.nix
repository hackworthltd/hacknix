final: prev:
let
  nmrpflash = final.callPackage ../pkgs/nmrpflash { };
in
{
  inherit nmrpflash;
}
