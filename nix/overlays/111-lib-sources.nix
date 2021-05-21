## Functions for cleaning local source directories. These are useful
## for filtering out files in your local repo that should not
## contribute to a Nix hash, so that you can just `src = ./.` in
## your derivation, and then filter that attribute after the fact.
##
## Note that these functions are composable, e.g., cleanSourceNix
## (cleanCabalStack ...) is a valid expression. They will also
## compose with any `lib.cleanSourceWith` function (but *not* with
## `builtins.filterSource`; see the `lib.cleanSourceWith`
## documentation).

final: prev:
let
  # In most cases, I believe that filtering Nix files from the source
  # hash is the right thing to do. They're obviously already evaluated
  # when a nix-build command is executed, so if *what they evaluate*
  # changes they'll cause a rebuild anyway, as they should; while
  # cosmetic changes (comments, formatting, etc.) won't.
  cleanSourceFilterNix = name: type:
    let baseName = baseNameOf (toString name); in
      ! (
        type != "directory" && (
          final.lib.hasSuffix ".nix" baseName
          || final.lib.hasPrefix "result-" baseName
          || baseName == "result"
        )
      );
  cleanSourceNix = src: final.lib.cleanSourceWith { filter = cleanSourceFilterNix; inherit src; };


  # Clean Haskell projects.
  cleanSourceFilterHaskell = name: type:
    let baseName = baseNameOf (toString name); in
      ! (
        baseName == ".cabal-sandbox"
        || final.lib.hasPrefix ".stack-work" baseName
        || final.lib.hasPrefix ".ghc.environment" baseName
        || baseName == "dist"
        || baseName == "dist-newstyle"
        || baseName == ".ghci"
        || baseName == ".stylish-haskell.yaml"
        || final.lib.hasSuffix ".hi" baseName
        || baseName == "cabal.sandbox.config"
        || baseName == "cabal.project"
        || baseName == "cabal.project.local"
        || baseName == "sources.txt"
      );
  cleanSourceHaskell = src: final.lib.cleanSourceWith { filter = cleanSourceFilterHaskell; inherit src; };


  # Clean system cruft, e.g., .DS_Store files on macOS filesystems.
  cleanSourceFilterSystemCruft = name: type:
    let baseName = baseNameOf (toString name); in
      ! (
        type != "directory" && (
          baseName == ".DS_Store"
        )
      );
  cleanSourceSystemCruft = src: final.lib.cleanSourceWith { filter = cleanSourceFilterSystemCruft; inherit src; };


  # Clean files related to editors and IDEs.
  cleanSourceFilterEditors = name: type:
    let baseName = baseNameOf (toString name); in
      ! (
        type != "directory" && (
          baseName == ".dir-locals.el"
          || baseName == ".netrwhist"
          || baseName == ".projectile"
          || baseName == ".tags"
          || baseName == ".vim.custom"
          || baseName == ".vscodeignore"
          || final.lib.hasPrefix "#" baseName
          || final.lib.hasPrefix ".#" baseName
          || final.lib.hasPrefix "flycheck_" baseName
          || builtins.match "^.*_flymake\\..*$" baseName != null
        )
      );
  cleanSourceEditors = src: final.lib.cleanSourceWith { filter = cleanSourceFilterEditors; inherit src; };


  # Clean maintainer files that don't affect Nix builds.
  cleanSourceFilterMaintainer = name: type:
    let baseName = baseNameOf (toString name); in
      ! (
        # Note: .git can be a file when it's in a submodule directory
        baseName == ".git"
        || (
          type != "directory" && (
            baseName == ".gitattributes"
            || baseName == ".gitignore"
            || baseName == ".gitmodules"
            || baseName == ".npmignore"
            || baseName == ".travis.yml"
          )
        )
      );
  cleanSourceMaintainer = src: final.lib.cleanSourceWith { filter = cleanSourceFilterMaintainer; inherit src; };


  # A cleaner that combines all of the cleaners defined here, plus
  # `lib.cleanSource` from Nixpkgs.
  cleanSourceAllExtraneous = src:
    cleanSourceMaintainer
      (
        cleanSourceEditors
          (
            cleanSourceSystemCruft
              (
                cleanSourceHaskell
                  (
                    cleanSourceNix
                      (final.lib.cleanSource src)
                  )
              )
          )
      );


  # Clean the `src` attribute of a package. This is convenient when
  # you use tools like `cabal2nix` to generate Nix files for local
  # source repos, as these tools generally lack the ability to
  # apply the various `clean*Source` functions to the `src`
  # attribute that they generate. Instead, you can apply this
  # function, plus one or more source cleaners, to a package that
  # is the result of a `callPackage` function application.
  cleanPackage = cleanSrc: pkg: (
    pkg.overrideAttrs (
      oldAttrs: {
        src = cleanSrc oldAttrs.src;
      }
    )
  );

  gitHubFlakeAttrs = inputName: lockFile:
    let
      lock = builtins.fromJSON (builtins.readFile lockFile);
      inherit (lock.nodes."${inputName}".locked) owner repo rev narHash;
      sha256 = narHash;
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    in
    {
      inherit owner repo rev narHash sha256 url;
    };

  ## Useful for importing whole directories.
  ##
  ## Thanks to dtzWill:
  ## https://github.com/dtzWill/nur-packages/commit/f601a6b024ac93f7ec242e6e3dbbddbdcf24df0b#diff-a013e20924130857c649dd17226282ff

  listDirectory = action: dir:
    let
      list = builtins.readDir dir;
      names = builtins.attrNames list;
      allowedName = baseName: !(
        # From lib/sources.nix, ignore editor backup/swap files
        builtins.match "^\\.sw[a-z]$" baseName != null
        || builtins.match "^\\..*\\.sw[a-z]$" baseName != null
        || # Otherwise it's good
        false
      );
      filteredNames = builtins.filter allowedName names;
    in
    builtins.listToAttrs (
      builtins.map
        (
          name: {
            name = builtins.replaceStrings [ ".nix" ] [ "" ] name;
            value = action (dir + ("/" + name));
          }
        )
        filteredNames
    );
  importDirectory = listDirectory import;
  pathDirectory = listDirectory (d: d);
  mkCallDirectory = callPkgs: listDirectory (p: callPkgs p { });

in
{
  lib = (prev.lib or { }) // {

    # XXX dhess - temporary fix for Rust build-support in upstream
    # nixpkgs.
    filterSource = builtins.filterSource;

    sources = (prev.lib.sources or { }) // {
      # Filters.
      inherit cleanSourceFilterNix;
      inherit cleanSourceFilterHaskell;
      inherit cleanSourceFilterSystemCruft;
      inherit cleanSourceFilterEditors;
      inherit cleanSourceFilterMaintainer;

      # cleanSource's.
      inherit cleanSourceNix;
      inherit cleanSourceHaskell;
      inherit cleanSourceSystemCruft;
      inherit cleanSourceEditors;
      inherit cleanSourceMaintainer;
      inherit cleanSourceAllExtraneous;

      inherit cleanPackage;

      inherit gitHubFlakeAttrs;

      inherit listDirectory pathDirectory importDirectory mkCallDirectory;
    };
  };
}
