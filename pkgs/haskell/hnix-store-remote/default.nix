{ mkDerivation, base, base64-bytestring, binary, bytestring
, containers, fetchgit, hnix-store-core, mtl, network, stdenv, text
, unix, unordered-containers
}:
mkDerivation {
  pname = "hnix-store-remote";
  version = "0.2.0.0";
  src = fetchgit {
    url = "https://github.com/hackworthltd/hnix-store";
    sha256 = "1qf5rn43d46vgqqgmwqdkjh78rfg6bcp4kypq3z7mx46sdpzvb78";
    rev = "516af6f95f339aef98674f4a3569309836885960";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/hnix-store-remote; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base base64-bytestring binary bytestring containers hnix-store-core
    mtl network text unix unordered-containers
  ];
  homepage = "https://github.com/haskell-nix/hnix-store";
  description = "Remote hnix store";
  license = stdenv.lib.licenses.asl20;
}
