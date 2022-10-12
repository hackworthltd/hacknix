final: prev:
let
  # A convenience function for importing directories full of NixOS
  # Python-style tests.
  importFromDirectory = dir: { hostPkgs, defaults ? { } }:
    let
      nixos-lib = import (final.path + "/nixos/lib") { };
    in
    final.lib.mapAttrs
      (name: test: nixos-lib.runTest {
        imports = [ test ];
        inherit name defaults hostPkgs;
      })
      (final.lib.sources.importDirectory dir);

in
{
  lib = (prev.lib or { }) // {
    testing = (prev.lib.testing or { }) // {
      nixos = (prev.lib.testing.nixos or { }) // {
        inherit importFromDirectory;
      };
    };
  };
}
