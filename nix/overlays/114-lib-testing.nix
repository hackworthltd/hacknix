final: prev:
let
  # A convenience function for importing directories full of NixOS
  # Python-style tests.
  importFromDirectory = dir: { system, pkgs, extraConfigurations ? [ ] }: testArgs:
    let
      testingPython = import (final.path + "/nixos/lib/testing-python.nix") {
        inherit system pkgs extraConfigurations;
      };
      callTest = test: test ({ inherit testingPython; } // testArgs);
    in
    final.lib.mapAttrs (_: test: callTest test)
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
