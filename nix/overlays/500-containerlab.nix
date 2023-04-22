final: prev:
let
  containerlab = final.callPackage ../pkgs/containerlab { };
in
{
  inherit containerlab;
}
