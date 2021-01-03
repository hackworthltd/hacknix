final: prev:
let
  nixUnstable = prev.nixUnstable.overrideAttrs (drv: {
    # Note: patches don't compose well in overlays -- if we try to add
    # this patch to drv.patches, then every time we include this
    # overlay in a subsequent overlay, it'll try to patch it again.
    # Therefore, we sort and unique-ify the list. :\

    patches = prev.lib.unique (prev.lib.sort (x: y: x < y) ((drv.patches or [ ]) ++ [
      # Work around nix issue; see:
      # https://github.com/NixOS/nix/pull/4264
      (prev.fetchpatch {
        url = "https://github.com/NixOS/nix/pull/4264.patch";
        sha256 = "sha256-pEvymyZLidu1Zn5LpRXcfRXF/cNqglDLx2HIGrbwksE=";
      })
    ]));
  });
  nixFlakes = nixUnstable;

in
{
  inherit nixUnstable nixFlakes;
}
