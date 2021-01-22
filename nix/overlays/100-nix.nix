final: prev:
let
  # Try to work around https://github.com/NixOS/nix/issues/4469, and
  # also log info when it occurs.
  nixUnstable = prev.nixUnstable.overrideAttrs (
    drv: {
      patches = [

        # Replicate the patch from upstream, since patches aren't
        # composable via overlays :(
        (final.fetchpatch {
          # Fix build on gcc10
          url = "https://github.com/NixOS/nix/commit/d4870462f8f539adeaa6dca476aff6f1f31e1981.patch";
          sha256 = "mTvLvuxb2QVybRDgntKMq+b6da/s3YgM/ll2rWBeY/Y=";
        })

        ../patches/nix/etag.patch
      ];
    }
  );
  nixFlakes = nixUnstable;

in
{
  inherit nixUnstable nixFlakes;
}
