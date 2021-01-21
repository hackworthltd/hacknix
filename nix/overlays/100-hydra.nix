final: prev:
let
  # Hydra fixes from various sources.
  hydra-unstable = final.lib.hacknix.flake.inputs.hydra.defaultPackage.x86_64-linux.overrideAttrs (
    drv: {
      patches = [
        # Secure GitHub token handling.
        (
          final.fetchpatch {
            url =
              "https://raw.githubusercontent.com/Holo-Host/holo-nixpkgs/00da3ac8e1e0dfe900df4a88eb0bced556abe525/overlays/holo-nixpkgs/hydra/secure-github.diff";
            sha256 = "0prinqi5smjkrc6jv8bs9gmnz3yga8ba9aacpg6cf1v1iq130iws";
          }
        )

        # Enable verbose mode in hydra-eval-jobs so that we can see
        # some semblance of progress in the logs.
        ../patches/hydra/verbose-hydra-eval-jobs.patch
      ];
    }
  );

in
{
  inherit hydra-unstable;
}
