self: super:

let

  # Some applications need a hashed X.509 certificate directory, per
  # OpenSSL's c_rehash(1).
  hashedCertDir = super.callPackage ../pkgs/build-support/hashed-cert-dir { };

in { inherit hashedCertDir; }
