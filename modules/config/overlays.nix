## Note: the local overlays are always enabled as these modules
## rely on them.

{ ... }:

let

  localLib = import ../../lib;

in
{
  nixpkgs.overlays = localLib.overlays;
}
