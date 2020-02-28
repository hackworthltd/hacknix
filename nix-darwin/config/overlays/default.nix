## Note: the overlays option is always enabled, as the modules depend
## on their functionality.

{ ... }:

let

  lib = import ../../../lib;

in
{
  nixpkgs.overlays = lib.overlays;
}
