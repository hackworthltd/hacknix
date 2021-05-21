final: prev:
let
  trimpcap = final.callPackage ../pkgs/trimpcap { };
in
{
  inherit trimpcap;
}
