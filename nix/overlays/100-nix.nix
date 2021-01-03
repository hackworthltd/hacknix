final: prev:
let
  nixUnstable = prev.nixUnstable.overrideAttrs (drv: {
    # This patch works around a Boehm GC issue; see
    # https://github.com/NixOS/nix/pull/4264
    #
    # Note: patches don't compose well in overlays. If we try to add
    # the patch to the list of prev's patches, then including this
    # overlay in a list of overlays where any of the previous overlays
    # also included it causes the patch to be applied again.
    #
    # Trying to sort and unique the list also doesn't work, because we
    # can't compare attrsets, and each individual patch in the list is
    # an attrset. (We could try to hash the patch attrsets or
    # something like that.)
    #
    # Therefore, we just override prev's patches. This is gross.
    patches = [
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
