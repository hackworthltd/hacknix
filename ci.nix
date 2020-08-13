{ supportedSystems ? [ builtins.currentSystem ]
, sourcesOverride ? { }
}:
let
  localLib = import nix/default.nix { inherit sourcesOverride; };
  trace = if builtins.getEnv "VERBOSE" == "1" then builtins.trace else (x: y: y);

  releasePkgs = import ./release.nix { inherit supportedSystems sourcesOverride; };

  # Add the ‘recurseForDerivations’ attribute to ensure that
  # nix-instantiate recurses into nested attribute sets.
  recurse = path: attrs:
    if (builtins.tryEval attrs).success then
      if localLib.isDerivation attrs
      then attrs
      else { recurseForDerivations = true; } //
        localLib.mapAttrs
          (n: v:
            let path' = path ++ [ n ]; in trace path' (recurse path' v))
          attrs
    else { };

  # Note that we only build native packages for now -- no NixOS tests,
  # as those require VM capabilities that aren't present on public
  # GitHub Actions runners.

in
recurse [ ] releasePkgs.native
