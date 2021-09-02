final: prev:
let
  cortextools = final.callPackage ../pkgs/cortextools { };
in
{
  inherit cortextools;
}
