final: prev:
let
  traefik-forward-auth = final.callPackage ../pkgs/traefik-forward-auth {
    src = final.lib.hacknix.flake.inputs.traefik-forward-auth;
    inherit (final.darwin.apple_sdk.frameworks) Security;
  };
in
{
  inherit traefik-forward-auth;
}
