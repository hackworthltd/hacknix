final: prev:
let
  nixUnstable = prev.nixUnstable.overrideAttrs (drv: {
    patches = (drv.patches or [ ]) ++ [
      # Work around nix issue; see:
      # https://github.com/NixOS/nix/pull/4264
      (prev.fetchpatch {
        url = "https://github.com/NixOS/nix/pull/4264.patch";
        sha256 = "sha256-pEvymyZLidu1Zn5LpRXcfRXF/cNqglDLx2HIGrbwksE=";
      })
    ];
  });
  nixFlakes = nixUnstable;

in
{
  inherit nixUnstable nixFlakes;
}
