final: prev:
let
  stdenv = prev.stdenv // {
    lib = final.lib;
  };
in
{
  # Workaround for broken packages, until they've caught up with
  # recent nixpkgs changes.
  inherit stdenv;
}
