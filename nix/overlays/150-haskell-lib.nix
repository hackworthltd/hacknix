final: prev:
let
  # A proper prev.haskellPackage.extend that fixes
  # https://github.com/NixOS/nixpkgs/issues/26561.
  #
  # Note that f takes prev: self: arguments, scoped within the
  # Haskell package set hp.

  properExtend =
    hp: f:
    hp.override (oldArgs: {
      overrides = final.lib.composeExtensions (oldArgs.overrides or (_: _: { })) f;
    });

  ## Sometimes you don't want any haddocks to be generated for an
  ## entire package set, rather than just a package here or there.
  noHaddocks =
    hp:
    (properExtend hp (
      self: prev: ({
        mkDerivation =
          args:
          prev.mkDerivation (
            args
            // {
              doHaddock = false;
            }
          );
      })
    ));
in
{
  haskell = (prev.haskell or { }) // {
    lib = (prev.haskell.lib or { }) // {
      inherit noHaddocks;
      inherit properExtend;
    };
  };
}
