{ pkgs ? import <nixpkgs> {}
, modules ? []
}:

{
  inherit (pkgs.lib.evalModules {
    inherit modules;
    specialArgs.modulesPath = ./.;

    # XXX dhess - NOTE: this is *crucial* to making the fake imported
    # modules here see our overlays.
    specialArgs.lib = pkgs.lib;

  }) config options
    ;
}
