final: prev:
let
  # Hydra fixes from various sources.
  hydra-unstable = prev.hydra-unstable.overrideAttrs (
    drv: {
      patches = [
        # Fix for latest nixUnstable.
        (
          final.fetchpatch {
            url = "https://github.com/NixOS/hydra/pull/840.diff";
            sha256 = "sha256-KPc1q36Mi/aJvm3n8ZxIdMHZwLNYnhz3NRsCR/iEtqU=";
          }
        )

        # Secure GitHub token handling.
        (
          final.fetchpatch {
            url =
              "https://raw.githubusercontent.com/Holo-Host/holo-nixpkgs/00da3ac8e1e0dfe900df4a88eb0bced556abe525/overlays/holo-nixpkgs/hydra/secure-github.diff";
            sha256 = "0prinqi5smjkrc6jv8bs9gmnz3yga8ba9aacpg6cf1v1iq130iws";
          }
        )

        # We have some git repos with private submodules. Allow Hydra
        # to continue evaluating when it can't check these out.
        ../patches/hydra/ignore-submodule-failures.patch
      ];
    }
  );

in
{
  inherit hydra-unstable;
}
