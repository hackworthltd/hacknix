{ mkDerivation, base, bytestring, fetchgit, hashable, libsodium
, profunctors, QuickCheck, semigroups, stdenv, test-framework
, test-framework-quickcheck2
}:
mkDerivation {
  pname = "saltine";
  version = "0.1.1.0";
  src = fetchgit {
    url = "https://github.com/tel/saltine.git";
    sha256 = "1k36573zz4a7v9sgw6b59n9hfid0bz1v21ks1701hpmrajr4szxn";
    rev = "8dc3e42bece934893013297f446f28198ae4562b";
    fetchSubmodules = true;
  };
  libraryHaskellDepends = [ base bytestring hashable profunctors ];
  libraryPkgconfigDepends = [ libsodium ];
  testHaskellDepends = [
    base bytestring QuickCheck semigroups test-framework
    test-framework-quickcheck2
  ];
  description = "Cryptography that's easy to digest (NaCl/libsodium bindings)";
  license = stdenv.lib.licenses.mit;
}
