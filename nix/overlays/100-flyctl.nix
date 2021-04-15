final: prev:
let
  # Upstream is way behind.
  flyctl = final.callPackage ../pkgs/flyctl { };

in
{
  inherit flyctl;
}
