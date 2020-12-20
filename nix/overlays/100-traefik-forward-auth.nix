final: prev:
let
  traefik-forward-auth = prev.callPackage ../pkgs/traefik-forward-auth {
    src = prev.lib.hacknix.flake.inputs.traefik-forward-auth;
    inherit (prev.darwin.apple_sdk.frameworks) Security;
  };
in
{
  inherit traefik-forward-auth;
}
