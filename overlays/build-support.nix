self: super:

let

  # Like dhallToNix, but from a file, rather than a literal string
  # argument. Note that this works only with a single, self-contained
  # Dhall file. If that Dhall file imports Dhall code from another
  # file, use dhallToNixFromSrc.
  dhallToNixFromFile = super.callPackage ../pkgs/build-support/dhall-to-nix-from-file {};


  # Create a Nix expression from an arbitrary Dhall program, given a
  # properly-defined Nixpkgs source expression and the file containing
  # the top-level Dhall expression. This works even if the top-level
  # Dhall expression imports other Dhall expressions.
  dhallToNixFromSrc = super.callPackage ../pkgs/build-support/dhall-to-nix-from-src {};


  ## We define a few dummy packages for testing dhallToNix* support.

  hello-dhall-file = dhallToNixFromFile ../pkgs/build-support/tests/hello.dhall;
  hello-dhall-src = dhallToNixFromSrc ../pkgs/build-support/tests/hello "hello.dhall";


  # Some applications need a hashed X.509 certificate directory, per
  # OpenSSL's c_rehash(1).
  hashedCertDir = super.callPackage ../pkgs/build-support/hashed-cert-dir {};

in
{
  inherit dhallToNixFromFile dhallToNixFromSrc;
  inherit hello-dhall-file hello-dhall-src;

  inherit hashedCertDir;
}
