{ mkDerivation, base, base16-bytestring, base64-bytestring, binary
, bytestring, containers, cryptohash-md5, cryptohash-sha1
, cryptohash-sha256, directory, fetchgit, filepath, hashable, mtl
, process, regex-base, regex-tdfa, saltine, stdenv, tasty
, tasty-discover, tasty-hspec, tasty-hunit, tasty-quickcheck
, temporary, text, time, unix, unordered-containers, vector
}:
mkDerivation {
  pname = "hnix-store-core";
  version = "0.2.0.0";
  src = fetchgit {
    url = "https://github.com/hackworthltd/hnix-store";
    sha256 = "1qf5rn43d46vgqqgmwqdkjh78rfg6bcp4kypq3z7mx46sdpzvb78";
    rev = "516af6f95f339aef98674f4a3569309836885960";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/hnix-store-core; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base base16-bytestring binary bytestring containers cryptohash-md5
    cryptohash-sha1 cryptohash-sha256 directory filepath hashable mtl
    regex-base regex-tdfa saltine text time unix unordered-containers
    vector
  ];
  testHaskellDepends = [
    base base64-bytestring binary bytestring containers directory
    process tasty tasty-discover tasty-hspec tasty-hunit
    tasty-quickcheck temporary text
  ];
  testToolDepends = [ tasty-discover ];
  homepage = "https://github.com/haskell-nix/hnix-store";
  description = "Core effects for interacting with the Nix store";
  license = stdenv.lib.licenses.asl20;
}
