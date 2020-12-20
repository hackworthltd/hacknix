final: prev:
let
  chamber = prev.callPackage ../pkgs/chamber {
    src = prev.lib.hacknix.flake.inputs.chamber;
    inherit (prev.darwin.apple_sdk.frameworks) Security;
  };
in
{
  inherit chamber;
}
