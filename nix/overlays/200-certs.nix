final: prev:
let
  # Some applications need a hashed X.509 certificate directory, per
  # OpenSSL's c_rehash(1).
  hashedCertDir = final.callPackage ../pkgs/hashed-cert-dir { };

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
  mkCacert = final.callPackage ../pkgs/custom-cacert;

in
{
  inherit mkCacert;
  inherit hashedCertDir;
}
