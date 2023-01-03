final: prev:
let
  lima = final.callPackage ../pkgs/lima {
    inherit (final.darwin) sigtool;
  };

  lima-binary = final.callPackage ../pkgs/lima/binary.nix { };
in
{
  inherit lima;
  inherit lima-binary;
}
