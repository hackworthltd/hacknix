{ lib, ... }:

{
  options = {
    value = lib.mkOption {
      type = lib.types.nonStorePath;
    };
  };
}
