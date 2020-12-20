final: prev:
let
  spago2nix = (import prev.lib.hacknix.flake.inputs.spago2nix {
    pkgs = prev;
  }).overrideAttrs (
    drv: {
      meta = (drv.meta or { }) // { platforms = prev.lib.platforms.all; };
    }
  );

in
{
  inherit spago2nix;
}
