final: prev:
let
  niks3 = import (final.lib.hacknix.flake.inputs.niks3 + "/nix/packages/niks3.nix") {
    inherit (final) lib go;
    pkgs = final;
  };
in
{
  inherit niks3;
}
