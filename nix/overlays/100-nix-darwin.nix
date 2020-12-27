final: prev:
let
  # A helper script for rebuilding nix-darwin systems.
  macnix-rebuild = final.callPackage ../pkgs/macnix-rebuild { };

in
{
  inherit macnix-rebuild;
}
