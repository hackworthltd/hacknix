final: prev:
let
  # A helper script for rebuilding nix-darwin systems.
  macnix-rebuild = prev.callPackage ../pkgs/macnix-rebuild { };

in
{
  inherit macnix-rebuild;
}
