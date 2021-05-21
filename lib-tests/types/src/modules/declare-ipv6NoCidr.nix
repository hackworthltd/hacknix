{ lib, ... }:

{
  options = {
    value = lib.mkOption {
      type = lib.types.ipv6NoCIDR;
    };
  };
}
