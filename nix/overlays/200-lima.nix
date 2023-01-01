final: prev:
let
  lima = final.callPackage ../pkgs/lima {
    inherit (final.darwin) sigtool;
  };
in
{
  inherit lima;
}
