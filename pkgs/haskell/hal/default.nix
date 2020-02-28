{ mkDerivation, aeson, base, bytestring, containers, envy
, exceptions, fetchgit, hpack, http-conduit, http-types, mtl
, stdenv, text, time
}:
mkDerivation {
  pname = "hal";
  version = "0.3.0";
  src = fetchgit {
    url = "https://github.com/Nike-Inc/hal.git";
    sha256 = "1r3mnqbl8w7vfawza504hv8h9wn3ybxmq01xlv95drdf8xxxazw1";
    rev = "9f8c97578578a12fa51d1e838e8cdca55f819413";
    fetchSubmodules = true;
  };
  libraryHaskellDepends = [
    aeson base bytestring containers envy exceptions http-conduit
    http-types mtl text time
  ];
  libraryToolDepends = [ hpack ];
  prePatch = "hpack";
  homepage = "https://github.com/Nike-inc/hal#readme";
  description = "A runtime environment for Haskell applications running on AWS Lambda";
  license = stdenv.lib.licenses.bsd3;
}
