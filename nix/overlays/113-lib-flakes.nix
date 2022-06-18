final: prev:
let
  # Filter a package set so that only packages whose platform(s)
  # attribute contain `system` are in the output set.
  #
  # If the package has no platform attribute, assume it's supported
  # only on x86_64-linux.
  filterPackagesByPlatform = system: pkgs:
    let
      packagePlatforms = pkg: pkg.meta.hydraPlatforms or pkg.meta.platforms or [ "x86_64-linux" ];
      supported = _: drv: builtins.elem system (packagePlatforms drv);

    in
    final.lib.filterAttrs supported pkgs;

  # nixosSystem is difficult to compose, and it's often useful to
  # extend the modules declared in a given configuration; e.g., to
  # override one or more module definitions. This function makes it
  # possible to add extra modules to a configuration.
  nixosSystem' = extraModules: config:
    final.lib.flakes.nixosSystem (config // {
      modules = (config.modules or [ ]) ++ extraModules;
    });

  # Like nixosSystem', but for building Amazon EC2 images. See
  # nixpkgs's /nixos/maintainers/scripts/ec2/amazon-image.nix for the
  # additional parameters that can be specified for Amazon EC2 images.
  amazonImage = extraModules: config:
    let
      extraModules' = [
        (final.path + "/nixos/maintainers/scripts/ec2/amazon-image.nix")
      ] ++ extraModules;
    in
    nixosSystem' extraModules' config;

  # Like nixosSystem', but for building ISO images. See nixpkgs's
  # /nixos/modules/installer/cd-dvd/installation-cd-minimal.nix for
  # the additional parameters that can be specified for ISO images.
  isoImage = extraModules: config:
    let
      extraModules' = [
        (final.path + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
      ] ++ extraModules;
    in
    nixosSystem' extraModules' config;

  # Like nixosSystem', but for using nixosGenerate from
  # nix-community:nixos-generators.
  nixosGenerate' = extraModules: args:
    final.lib.flakes.nixosGenerate (args // {
      modules = (args.modules or [ ]) ++ extraModules;
    });

  # Import a directory full of
  # nixosConfigurations/darwinConfigurations and apply a function that
  # has the same shape as nixosSystem.
  importFromDirectory = nixosSystemFn: dir: args:
    final.lib.mapAttrs
      (_: cf:
        let config = cf args;
        in nixosSystemFn config)
      (final.lib.sources.importDirectory dir);

  # Create an attrset of buildable nixosConfigurations, using any
  # attribute in the `config.system.build` attrset. This is useful for
  # building via a Nix Flake's `hydraJobs`.
  #
  # Originally from:
  # https://github.com/Mic92/doctor-cluster-config/blob/d9964365bb112898fe2b4abb77a8408adf8b1cb5/flake.nix#L36
  build' = attr: configurations:
    final.lib.mapAttrs'
      (name: config: final.lib.nameValuePair name config.config.system.build.${attr})
      configurations;

  # Build the `toplevel` attribute (e.g., something that can be
  # deployed to a live system or container).
  build = build' "toplevel";

  # Build the `amazonImage` attribute. Use with amazonImage.
  buildAmazonImages = build' "amazonImage";

  # Build the `isoImage` attribute. Use with isoImage.
  buildISOImages = build' "isoImage";

  # Like nixosSystem' for darwinSystem.
  darwinSystem' = extraModules: config:
    final.lib.flakes.darwinSystem (config // {
      modules = (config.modules or [ ]) ++ extraModules;
    });


  # Given a flake's hydraJobs, recurse into it setting
  # `recurseForDerivation` along the way. This is useful for
  # converting a flake's hydraJobs to something that
  # `nix-build/nix-instantiate` can build.
  #
  # Also cleans derviation names by converting code points that some
  # nix tools tend to choke on (e.g., ":") to something more
  # universally acceptable.
  recurseIntoHydraJobs = set:
    let
      scrubForNix = name: builtins.replaceStrings [ ":" ] [ "-" ] name;
      recurse = path: set:
        let
          g =
            name: value: final.lib.nameValuePair (scrubForNix name) (
              if final.lib.isAttrs value
              then ((recurse (path ++ [ name ]) value) // { recurseForDerivations = true; })
              else value
            );
        in
        final.lib.mapAttrs' g set;
    in
    recurse [ ] set;

  # Same as `recurseIntoHydraJobs`, but without the name scrubbing.
  recurseIntoHydraJobs' = set:
    let
      recurse = path: set:
        let
          g =
            name: value:
            if final.lib.isAttrs value
            then ((recurse (path ++ [ name ]) value) // { recurseForDerivations = true; })
            else value;
        in
        final.lib.mapAttrs g set;
    in
    recurse [ ] set;
in
{
  lib = (prev.lib or { }) // {
    flakes = (prev.lib.flakes or { }) // {
      inherit filterPackagesByPlatform;

      inherit nixosSystem';
      inherit amazonImage isoImage;
      inherit nixosGenerate';

      nixosConfigurations = (prev.lib.flakes.nixosConfigruations or { }) // {
        inherit importFromDirectory;
        inherit build' build buildAmazonImages buildISOImages;
      };

      inherit darwinSystem';

      darwinConfigurations = (prev.lib.flakes.darwinConfigurations or { }) // {
        inherit importFromDirectory;
        inherit build' build;
      };

      nixosGenerators = (prev.lib.flakes.nixosGenerators or { }) // {
        inherit importFromDirectory;
        inherit build' build;
      };

      inherit recurseIntoHydraJobs;
    };
  };
}
