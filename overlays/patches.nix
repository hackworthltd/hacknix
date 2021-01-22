self: super:
let
  # Hydra fixes from various sources.
  hydra-unstable = super.hydra-unstable.overrideAttrs (
    drv: {
      patches = [
        # Secure GitHub token handling.
        (
          super.fetchpatch {
            url =
              "https://raw.githubusercontent.com/Holo-Host/holo-nixpkgs/00da3ac8e1e0dfe900df4a88eb0bced556abe525/overlays/holo-nixpkgs/hydra/secure-github.diff";
            sha256 = "0prinqi5smjkrc6jv8bs9gmnz3yga8ba9aacpg6cf1v1iq130iws";
          }
        )

        # Enable verbose mode in hydra-eval-jobs so that we can see
        # some semblance of progress in the logs.
        ../patches/hydra/verbose-hydra-eval-jobs.patch

        # We have some git repos with private submodules. Allow Hydra
        # to continue evaluating when it can't check these out.
        ../patches/hydra/ignore-submodule-failures.patch
      ];
    }
  );

  # Try to work around https://github.com/NixOS/nix/issues/4469, and
  # also log info when it occurs.
  nixUnstable = super.nixUnstable.overrideAttrs (
    drv: {
      patches = [

        # Replicate the patch from upstream, since patches aren't
        # composable via overlays :(
        (super.fetchpatch {
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
  inherit hydra-unstable;
  inherit nixUnstable nixFlakes;
}
