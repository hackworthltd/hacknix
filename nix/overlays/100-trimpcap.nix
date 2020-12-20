final: prev:
let
  trimpcap = prev.callPackage ../pkgs/trimpcap { };
in
{
  inherit trimpcap;
}
