# # Note: the local overlays are always enabled as these modules
## rely on them.

{ ... }:
let
  localLib = import ../../nix { };
in
{ nixpkgs.overlays = localLib.overlays; }
