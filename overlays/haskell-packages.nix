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
    HsYAML = super.HsYAML_0_2_1_0;

    algebra = doJailbreak super.algebra;
    amazonka = doJailbreak super.amazonka;
    amazonka-core = doJailbreak super.amazonka-core;
    bloodhound = doJailbreak super.bloodhound;

    clay = doJailbreak super.clay;
    concurrent-machines = doJailbreak super.concurrent-machines;

    # dhall tests try to hit the network.
    dhall = dontCheck super.dhall_1_29_0;

    # Fix upstream breakage.
    dhall-json = super.dhall-json_1_6_1.override {
      prettyprinter = self.prettyprinter_1_6_0;
      prettyprinter-ansi-terminal =
        self.prettyprinter-ansi-terminal.override {
          prettyprinter = self.prettyprinter_1_6_0;
        };
    };

    doctest-driver-gen = dontCheck (super.doctest-driver-gen.overrideAttrs (drv: {
      broken = false;
      meta.hydraPlatforms = stdenv.lib.platforms.all;
    }));

    generic-lens = dontCheck super.generic-lens_1_2_0_1;

    # Ironically, haddock-api doesn't haddock.
    haddock-api =  dontHaddock (doJailbreak super.haddock-api);
    haddock-library = super.haddock-library_1_8_0;

    hal = super.callPackage ../pkgs/haskell/hal {};

    haskell-lsp = super.haskell-lsp_0_20_0_1;
    haskell-lsp-types = super.haskell-lsp-types_0_20_0_0;

    haxl = doJailbreak (super.callPackage ../pkgs/haskell/haxl {});

    hedgehog-classes = super.callPackage ../pkgs/haskell/hedgehog-classes {};

    hex = doJailbreak super.hex;

    hie-bios = dontCheck super.hie-bios;

    hoopl = doJailbreak super.hoopl;

    hw-balancedparens = super.hw-balancedparens_0_3_0_4;

    hw-bits = doJailbreak super.hw-bits;
    hw-excess = doJailbreak super.hw-excess;
    hw-json = super.hw-json_1_3_1_1;

    hw-rankselect = dontCheck super.hw-rankselect_0_13_3_2;
    hw-rankselect-base = doJailbreak super.hw-rankselect-base;
    insert-ordered-containers = doJailbreak super.insert-ordered-containers;

    # One test is superficially broken.
    ip = dontCheck (super.ip_1_7_1);

    ivory = doJailbreak super.ivory;
    katip-elasticsearch = dontCheck super.katip-elasticsearch;
    hfsevents = super.hfsevents.overrideAttrs (drv: {
      meta.hydraPlatforms = stdenv.lib.platforms.darwin;
    });

    lsp-test = dontCheck super.lsp-test_0_9_0_0;

    machines = super.machines_0_7;
    machines-binary = doJailbreak super.machines-binary;
    machines-directory = doJailbreak super.machines-directory;
    machines-io = doJailbreak super.machines-io;
    machines-process = doJailbreak super.machines-process;

    # Undo upstream breakage.
    network-bsd = super.network-bsd.override { network = super.network; };

    pipes-errors = doJailbreak super.pipes-errors;
    pipes-text = doJailbreak super.pipes-text;
    pipes-transduce = dontCheck super.pipes-transduce;
    prettyprinter = super.prettyprinter_1_6_0;

    # dontCheck, or else it causes infinite recursion.
    primitive = dontCheck super.primitive_0_7_0_0;

    primitive-extras = super.primitive-extras_0_8;
    primitive-unlifted = dontCheck (doJailbreak super.primitive-unlifted);
    quickcheck-classes = super.quickcheck-classes_0_6_4_0;
    serialise = doJailbreak super.serialise;
    servant-docs = doJailbreak super.servant-docs;
    stm-hamt = doJailbreak super.stm-hamt;
    stream-monad = doJailbreak super.stream-monad;
    streaming-utils = doJailbreak super.streaming-utils;

    tdigest = doJailbreak super.tdigest;
    these = doJailbreak super.these;

    time-recurrence = doJailbreak super.time-recurrence;

    # Disable tests on aarch64-linux; the doctests cause an internal error.
    trifecta = if stdenv.hostPlatform.isAarch64 then dontCheck super.trifecta else super.trifecta;

    wide-word = doJailbreak super.wide-word;

    # Disable tests on aarch64-linux; the doctests cause an internal error.
    zippers = if stdenv.hostPlatform.isAarch64 then dontCheck super.zippers else super.zippers;
  });

  # The current GHC.
  haskellPackages = mkHaskellPackages super.haskellPackages;

  # ghcide currently has special requirements.
  mkGhcidePackages = hp: properExtend hp (self: super: {
    regex-base = super.regex-base_0_94_0_0;
    regex-posix = super.regex-posix_0_96_0_0;
    regex-tdfa = super.regex-tdfa_1_3_1_0;

    ghcide = dontCheck (super.callPackage ../pkgs/haskell/ghcide {});
  });

  ghcide = exeOnly (mkGhcidePackages haskellPackages).ghcide;

  ## Package sets that we want to be built.

  # A list of currently-problematic packages, things that can't easily
  # be fixed by overrides.
  problems = hp: with hp; [
    ivory
    show-prettyprint
  ];

  mkInstalledPackages = desired: problems: hp:
    super.lib.subtractLists (problems hp) (desired hp);

  # A list of "core" Haskell packages that we want to build for any
  # given release of this overlay.
  coreList = hp: with hp; [
    acid-state
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
    dhall
    dhall-json
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
    monad-logger-syslog
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
    dhall-nix
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
    hoopl
    hw-hedgehog
    hw-hspec-hedgehog
    hw-json
    hw-json-simd
    intervals
    ip
    ivory
    justified-containers
    katip
    katip-elasticsearch
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
    machines-binary
    machines-directory
    machines-io
    machines-process
    memory
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
    time-recurrence
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
        (all-hies.selection { selector = p: { inherit (p) ghc865; }; })
        ghcide
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

  inherit ghcide;
}
