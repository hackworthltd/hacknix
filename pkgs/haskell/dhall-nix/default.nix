{ mkDerivation, base, containers, data-fix, dhall, fetchgit, hnix
, neat-interpolation, optparse-generic, stdenv, text
}:
mkDerivation {
  pname = "dhall-nix";
  version = "1.1.12";
  src = fetchgit {
    url = "https://github.com/dhall-lang/dhall-haskell.git";
    sha256 = "1kvi6x8k1fak5agv5rkmpzh4j494b8adjvbngjfzlvd3lljhaxm5";
    rev = "7005842d80c25a2d73a027259fd52d3060c48f76";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/dhall-nix; echo source root reset to $sourceRoot";
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    base containers data-fix dhall hnix neat-interpolation text
  ];
  executableHaskellDepends = [
    base dhall hnix optparse-generic text
  ];
  description = "Dhall to Nix compiler";
  license = stdenv.lib.licenses.bsd3;
}
