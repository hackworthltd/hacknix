final: prev:
let

  # Upstream prevents fsatrace from building on macOS. It should work,
  # more or less, as long as you're using it with binaries built from
  # Nixpkgs and not pulling in Apple frameworks.
  fsatrace = prev.fsatrace.overrideAttrs (drv: {
    meta = drv.meta // {
      platforms = final.lib.platforms.unix;
    };
  });


in
{
  inherit fsatrace;
}
