final: prev:
let
  forAllSystems = systems: f: prev.lib.genAttrs systems (system: f system);

  # These functions are useful for building package sets from
  # stand-alone overlay repos.

  # This function is from nixpkgs, but uses "self" and "super" rather
  # than "final" and "prev"; hence, it fails `nix flake check` :\.
  composeExtensions =
    f: g: final: prev:
    let
      fApplied = f final prev;
      prev' = prev // fApplied;
    in
    fApplied // g final prev';

  combine = builtins.foldl' composeExtensions (_: _: { });

  combineFromFiles = overlaysFiles:
    combine (map import overlaysFiles);

  combineFromDir = dir:
    let
      files = prev.lib.filesystem.listFilesRecursive dir;
    in
    combineFromFiles files;

in
{
  lib = (prev.lib or { }) // {
    flakes = (prev.lib.flakes or { }) // {
      inherit forAllSystems;
    };
    overlays = (prev.lib.overlays or { }) // {
      inherit composeExtensions combine combineFromFiles combineFromDir;
    };
  };
}
