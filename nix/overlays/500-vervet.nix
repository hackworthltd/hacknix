final: prev:
let
  vervet = final.callPackage ../pkgs/vervet {
    inherit (final.darwin.apple_sdk.frameworks) PCSC;
  };
in
{
  inherit vervet;
}
