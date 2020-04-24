self: super:

let

  localLib = import ../../lib;

  # Create the text of a znc config file, so that it can be securely
  # deployed to a NixOS host without putting it in the Nix store.
  #
  # XXX dhess - this is a hack and should be revisited.
  mkZncConfig = (import ../../modules/services/znc/conf.nix);

  # A list of all the NixOS test modules exported by this package.
  #
  # NOTE: do NOT use these in production. They will do bad
  # things, like writing secrets to your Nix store. Use them ONLY
  # for testing. You have been warned!
  testModulesList = ../../test-modules/module-list.nix;

  # All the NixOS test modules exported by this package.
  #
  # NOTE: do NOT use these in production. They will do bad
  # things, like writing secrets to your Nix store. Use them ONLY
  # for testing. You have been warned!
  testModules = import testModulesList;

  # A convenience function for creating nix-darwin systems.
  mkNixDarwinSystem = configuration:
    import (localLib.fixedNixDarwin) {
      nixpkgs = localLib.fixedNixpkgs;
      system = "x86_64-darwin";
      inherit configuration;
    };

in {
  lib = (super.lib or { }) // {
    hacknix = (super.lib.hacknix or { }) // {
      inherit mkZncConfig;

      inherit (localLib) modules modulesList;
      inherit (localLib) path;
      inherit (localLib) sources;

      inherit (localLib) nixDarwinModules nixDarwinModulesList;
      inherit mkNixDarwinSystem;

      # Provide access to our nixpkgs, if anyone downstream wants to use it.
      inherit (localLib) nixpkgs;

      # Provide access to our nix-darwin, if anyone downstream wants to use it.
      inherit (localLib) nix-darwin;

      testing = (super.lib.hacknix.testing or { }) // {
        inherit testModules testModulesList;
      };
    };

    fetchers = (super.lib.fetchers or { }) // {
      inherit (localLib) fixedNixpkgs fixedNixOps;
      inherit (localLib) fixedNixDarwin;
    };
  };
}
