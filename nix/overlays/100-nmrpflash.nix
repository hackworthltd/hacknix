final: prev:
let
  nmrpflash = prev.callPackage ../pkgs/nmrpflash { };
in
{
  inherit nmrpflash;
}
