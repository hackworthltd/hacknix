final: prev:
let
  # Note: creating a function for this if-then-else pattern causes
  # infinite recursion, so we have to write it by hand each time.

  nix-index = if final.stdenv.hostPlatform.system == "aarch64-darwin" then final.lib.hacknix.pkgs_x86.nix-index else prev.nix-index;
in
{
  inherit nix-index;
}
