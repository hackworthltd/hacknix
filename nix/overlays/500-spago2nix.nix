final: prev:
let
  spago2nix = (import final.lib.hacknix.flake.inputs.spago2nix {
    pkgs = final;
  }).overrideAttrs (
    drv: {
      meta = (drv.meta or { }) // { platforms = final.lib.platforms.all; };
    }
  );

in
{
  inherit spago2nix;
}
