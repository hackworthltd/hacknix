final: prev:
let
  chamber = final.callPackage ../pkgs/chamber {
    src = final.lib.hacknix.flake.inputs.chamber;
    inherit (final.darwin.apple_sdk.frameworks) Security;
  };
in
{
  inherit chamber;
}
