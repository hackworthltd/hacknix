{ lib, ... }:

{
  options = {
    value = lib.mkOption {
      type = lib.types.addrOptsV4;
    };
  };
}
