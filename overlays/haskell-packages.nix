self: super:

let

  localLib = import ../lib;

  inherit (super) stdenv fetchpatch;
  inherit (super.haskell.lib) appendPatch doJailbreak dontCheck dontHaddock properExtend;


  ## Useful functions.

  exeOnly = super.haskell.lib.justStaticExecutables;


  ## Haskell package fixes for various versions of GHC, based on the
  ## current nixpkgs snapshot that we're using.

  mkHaskellPackages = hp: properExtend hp (self: super: {
    concurrent-machines = doJailbreak super.concurrent-machines;
    doctest-driver-gen = dontCheck super.doctest-driver-gen;
    hal = doJailbreak super.hal;
    hedgehog-classes = doJailbreak super.hedgehog-classes;
    hie-bios = dontCheck super.hie-bios;
    machines-io = doJailbreak super.machines-io;
    monad-logger-syslog = doJailbreak super.monad-logger-syslog;
    pipes-text = doJailbreak super.pipes-text;
    pipes-errors = doJailbreak super.pipes-errors;
    pipes-transduce = dontCheck super.pipes-transduce;

    Agda = dontCheck (super.callPackage ../pkgs/haskell/Agda {});
    ghcide = dontCheck (super.callPackage ../pkgs/haskell/ghcide {});
    hnix = dontCheck (super.callPackage ../pkgs/haskell/hnix {});
    hnix-store-core = super.callPackage ../pkgs/haskell/hnix-store-core {};
    ivory = super.callPackage ../pkgs/haskell/ivory {};
    saltine = dontCheck (super.callPackage ../pkgs/haskell/saltine {});
  });

  # The current GHC.
  haskellPackages = mkHaskellPackages super.haskellPackages;

  ghcide = exeOnly haskellPackages.ghcide;

  # cachix.
  mkCachixPackages = hp: properExtend hp (self: super: {
    cachix = (import localLib.fixedCachix);
  });

  cachix = exeOnly (mkCachixPackages haskellPackages).cachix;

  ## Package sets that we want to be built.

  # A list of currently-problematic packages, things that can't easily
  # be fixed by overrides.
  problems = hp: with hp; [
    accelerate
    bloodhound
    configuration-tools
    haxl
    hex
    linear-accelerate
    show-prettyprint
  ];

  mkInstalledPackages = desired: problems: hp:
    super.lib.subtractLists (problems hp) (desired hp);

  # A list of "core" Haskell packages that we want to build for any
  # given release of this overlay.
  coreList = hp: with hp; [
    aeson
    aeson-pretty
    alex
    algebra
    async
    attoparsec
    base-compat
    bifunctors
    binary
    bits
    boring
    bytes
    bytestring
    cereal
    charset
    comonad
    cond
    conduit
    containers
    contravariant
    criterion
    cryptonite
    data-fix
    data-has
    deepseq
    directory
    distributive
    doctest
    either
    errors
    exceptions
    fail
    filepath
    foldl
    folds
    free
    generic-lens
    groupoids
    happy
    haskeline
    hedgehog
    hedgehog-quickcheck
    hlint
    hscolour
    hspec
    hspec-expectations-lens
    hspec-megaparsec
    hspec-wai
    http-api-data
    http-client
    http-client-tls
    http-types
    inline-c
    iproute
    kan-extensions
    lens
    lens-aeson
    managed
    megaparsec
    monad-control
    monad-logger
    mtl
    network
    network-bsd
    optparse-applicative
    optparse-text
    parsec
    parsers
    path
    path-io
    pipes
    pipes-bytestring
    pipes-safe
    prettyprinter
    profunctors
    protolude
    QuickCheck
    quickcheck-instances
    recursion-schemes
    reflection
    resourcet
    safe
    safe-exceptions
    semigroupoids
    semigroups
    servant
    servant-client
    servant-docs
    servant-lucid
    servant-server
    servant-swagger
    servant-swagger-ui
    show-prettyprint
    singletons
    stm
    streaming
    streaming-bytestring
    streaming-utils
    strict
    swagger2
    tasty
    tasty-hedgehog
    text
    time
    transformers
    transformers-base
    transformers-compat
    trifecta
    unix
    unix-bytestring
    unix-compat
    unordered-containers
    vector
    vector-instances
    wai
    wai-extra
    warp
    zippers
  ];

  # A combinator that takes a haskellPackages and returns a list of
  # core packages that we want built from that haskellPackages set,
  # minus any problematic packages.
  coreHaskellPackages = mkInstalledPackages coreList problems;


  # A list of extra packages that would be nice to build for any given
  # release of this overlay, but aren't showstoppers.
  extraList = hp: with hp; (coreList hp) ++ [
    Agda
    accelerate
    acid-state
    ad
    amazonka
    amazonka-ec2
    amazonka-route53
    amazonka-route53-domains
    amazonka-s3
    amazonka-sns
    amazonka-sqs
    approximate
    auto
    autoexporter
    auto-update
    blaze-html
    blaze-markup
    bloodhound
    clay
    concurrent-machines
    conduit-combinators
    configurator
    configuration-tools
    constraints
    doctest-driver-gen
    fgl
    fmt
    formatting
    gdp
    GraphSCC
    graphs
    hal
    haxl
    hedgehog-classes
    hedgehog-corpus
    hedgehog-fn
    hex
    hnix
    hw-hedgehog
    hw-hspec-hedgehog
    hw-json
    hw-json-simd
    intervals
    ip
    ivory
    justified-containers
    lens-action
    lifted-async
    lifted-base
    linear
    linear-accelerate
    list-t
    llvm-hs-pure
    lucid
    lzma
    machines
    memory
    monad-logger-syslog
    mustache
    neat-interpolation
    numeric-extras
    pipes-attoparsec
    pipes-errors
    pipes-group
    process
    process-streaming
    reducers
    regex-applicative
    repline
    safecopy
    sbv
    semirings
    shake
    shelly
    smtLib
    stm-containers
    streams
    tagged
    tar
    tasty-hunit
    temporary
    turtle
    type-of-html
    uniplate
    webdriver
    zlib-lens
  ];

  # A combinator that takes a haskellPackages and returns a list of
  # extensive packages that we want built from that haskellPackages
  # set, minus any problematic packages.
  extensiveHaskellPackages = mkInstalledPackages extraList problems;

  # haskell-ide-engine via all-hies.
  inherit (localLib) all-hies;

  ## Create a buildEnv with useful Haskell tools and the given set of
  ## haskellPackages and a list of packages to install in the
  ## buildEnv.

  mkHaskellBuildEnv = name: hp: packageList:
  let
    paths =  [
        (hp.ghcWithHoogle packageList)
        (all-hies.selection { selector = p: { inherit (p) ghc882; }; })
        (exeOnly hp.ghcide)
        (exeOnly hp.cabal-install)
        (exeOnly hp.hpack)
        (exeOnly hp.structured-haskell-mode)
        (exeOnly hp.stylish-haskell)
        (exeOnly hp.brittany)
    ];
  in
  super.buildEnv
    {
      inherit name paths;
      meta.platforms = hp.ghc.meta.platforms;
    };

  haskell-env = mkHaskellBuildEnv "haskell-env" haskellPackages coreHaskellPackages;  
  extensive-haskell-env = mkHaskellBuildEnv "extensive-haskell-env" haskellPackages extensiveHaskellPackages;  

in
{
  inherit haskellPackages;


  ## Haskell package combinators.

  inherit coreHaskellPackages;
  inherit extensiveHaskellPackages;


  ## Haskell buildEnv's.

  inherit mkHaskellBuildEnv;
  inherit haskell-env;
  inherit extensive-haskell-env;

  ## haskell-ide-engine.

  inherit all-hies;


  ## Executables only.

  inherit cachix;
  inherit ghcide;
}
