{ lib, pkgs, ... }:

{
  options = {
    value = lib.mkOption {
      type = lib.types.storePath;
    };
  };
}
