final: prev:
let
  # Hydra fixes from iohk and other various sources.
  hydra-unstable = final.lib.hacknix.flake.inputs.hydra.defaultPackage.x86_64-linux.overrideAttrs (
    drv: {
      patches = [
        (
          final.fetchpatch {
            url =
              "https://github.com/input-output-hk/hydra/commit/ed87d2ba82807d30d91d70a88cda276083ef4e79.patch";
            sha256 = "0mzmm480cs085wbbn1ha6ml164v0dslfh0viak73mc84rvl00ckb";
          }
        )
        (
          final.fetchpatch {
            url =
              "https://github.com/input-output-hk/hydra/commit/96ec35acface848c546b67e6b835094412a488d9.patch";
            sha256 = "0ax4bn1ivk5yg5mbdkcqbqc2vrjlyk9km2rzg1k1kqc81ka570a2";
          }
        )
        (
          final.fetchpatch {
            url =
              "https://github.com/input-output-hk/hydra/commit/0768891e3cd3ef067d28742098f1dea8462fca75.patch";
            sha256 = "0m4009pmi4sl0vwq6q98bzp4hpnfr4ww1j27czwcazbda7l8fdzy";
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

        # Disable restrictEval until we can work out the gitignoreSource issue.
        ../patches/hydra/hydra-no-restrict.patch
        # (final.fetchpatch {
        #   url =
        #     "https://github.com/NixOS/hydra/commit/2f9d422172235297759f2b224fe0636cad07b6fb.patch";
        #   sha256 = "0152nsqqc5d85qdygmwrsk88i9y6nk1b639fj2n042pjvr0kpz6k";
        # })
        # Broken on hydra-unstable.
        # (final.fetchpatch {
        #   url = "https://github.com/input-output-hk/hydra/commit/11db34b6a9243a428b3d5935c65ac13a8080d02c.patch";
        #   sha256 = "10b9ywif14gncf1j9647hhpbqh67yy0pv1c8f38f08v68a83993s";
        # })
      ];
    }
  );

in
{
  inherit hydra-unstable;
}
