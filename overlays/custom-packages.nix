self: super:

let

  lib = import ../lib;

  inherit (super) callPackage;

  nixpkgsPath = (import lib.fixedNixpkgs { }).path;
  nixops = import lib.fixedNixOps { nixpkgs = nixpkgsPath; };

  lorri = (import lib.fixedLorri) { pkgs = super; };

  ccextractor = callPackage ../pkgs/multimedia/ccextractor { };

  gawk_4_2_1 = callPackage ../pkgs/gawk/4.2.1.nix { };

  libprelude =
    callPackage ../pkgs/development/libraries/libprelude { gawk = gawk_4_2_1; };

  # When called with an argument `extraCerts` whose value is a set
  # mapping strings containing human-friendly certificate authority
  # names to PEM-formatted public CA certificates, this function
  # creates derivation similar to that provided by `super.cacert`, but
  # whose CA cert bundle contains the user-provided extra
  # certificates.
  #
  # For example:
  #
  #   extraCerts = { "Example CA Root Cert" = "-----BEGIN CERTIFICATE-----\nMIIC+..." };
  #   myCacert = mkCacert { inherit extraCerts };
  #
  # will create a new derivation `myCacert` which can be substituted
  # for `super.cacert` wherever that derivation is used, so that, e.g.:
  #
  #   myFetchGit = callPackage <nixpkgs/pkgs/build-support/fetchgit> { cacert = self.myCacert; };
  #
  # creates a `fetchgit` derivation that will accept certificates
  # created by the "Example CA Root Cert" given above.
  #
  # The cacert package in Nixpkgs allows the user to provide extra
  # certificates; however, these extra certificates are not visible to
  # some packages which hard-wire their cacert package, such as many
  # of nixpkgs's fetch functions. It's for that reason that this
  # function exists.
  mkCacert = (callPackage ../pkgs/security/custom-cacert.nix);

  badhosts = callPackage ../pkgs/dns/badhosts {
    lib = super.lib;
    source = lib.fixedBadhosts;
  };

  trimpcap = callPackage ../pkgs/misc/trimpcap { };

  tsoff = callPackage ../pkgs/networking/tsoff { };

  terraform-provider-okta = callPackage ../pkgs/terraform/providers/okta {
    source = lib.sources.terraform-provider-okta;
  };

  hacknix-source =
    callPackage ../pkgs/hacknix-source { inherit (super) packageSource; };

  hyperkit = callPackage ../pkgs/hyperkit {
    inherit (super.darwin.apple_sdk.frameworks)
      Hypervisor vmnet SystemConfiguration;
    inherit (super.darwin.apple_sdk.libs) xpc;
    inherit (super.darwin) libobjc dtrace;
  };

  chamber = callPackage ../pkgs/chamber {
    source = lib.sources.chamber;
    inherit (super.darwin.apple_sdk.frameworks) Security;
  };

  nmrpflash = callPackage ../pkgs/nmrpflash { };

  # A helper script for rebuilding nix-darwin systems.
  macnix-rebuild = callPackage ../pkgs/macnix-rebuild { };

  gitignoreSrc = (import lib.fixedGitignoreNix) { inherit (super) lib; };

  traefik-forward-auth = callPackage ../pkgs/traefik-forward-auth {
    inherit (super.darwin.apple_sdk.frameworks) Security;
  };

  delete-tweets = super.callPackage ../pkgs/python/delete-tweets { };

in {
  inherit (badhosts) badhosts-unified;
  inherit (badhosts)
    badhosts-fakenews badhosts-gambling badhosts-nsfw badhosts-social;
  inherit (badhosts)
    badhosts-fakenews-gambling badhosts-fakenews-nsfw badhosts-fakenews-social;
  inherit (badhosts) badhosts-gambling-nsfw badhosts-gambling-social;
  inherit (badhosts) badhosts-nsfw-social;
  inherit (badhosts)
    badhosts-fakenews-gambling-nsfw badhosts-fakenews-gambling-social;
  inherit (badhosts) badhosts-fakenews-nsfw-social;
  inherit (badhosts) badhosts-gambling-nsfw-social;
  inherit (badhosts) badhosts-fakenews-gambling-nsfw-social;
  inherit (badhosts) badhosts-all;

  inherit (gitignoreSrc) gitignoreSource gitignoreFilter;

  inherit ccextractor;
  inherit chamber;
  inherit delete-tweets;
  inherit hacknix-source;
  inherit gawk_4_2_1;
  inherit hyperkit;
  inherit libprelude;
  inherit lorri;
  inherit macnix-rebuild;
  inherit mkCacert;
  inherit nixops;
  inherit nmrpflash;
  inherit terraform-provider-okta;
  inherit traefik-forward-auth;
  inherit trimpcap;
  inherit tsoff;
}
