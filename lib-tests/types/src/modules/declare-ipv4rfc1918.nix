{ lib, ... }:

{
  options = {
    value = lib.mkOption {
      type = lib.types.ipv4RFC1918;
    };
  };
}
