## Additional useful types, mostly for NixOS modules.

final: prev:
let
  inherit (final.lib) all ipaddr mkOption stringToCharacters types;
  inherit (final.lib.secrets) resolvesToStorePath;

  addCheckDesc = desc: elemType: check: types.addCheck elemType check
    // { description = "${elemType.description} (with check: ${desc})"; };

  ## String types.

  nonEmptyStr = addCheckDesc "non-empty" types.str
    (x: x != "" && ! (all (c: c == " " || c == "\t") (stringToCharacters x)));


  ## Path types.

  storePath = addCheckDesc "in the Nix store" types.path resolvesToStorePath;
  nonStorePath = addCheckDesc "not in the Nix store" types.path
    (x: ! resolvesToStorePath x);


  ## IP addresses.

  ipv4 = addCheckDesc "valid IPv4 address" types.str ipaddr.isIPv4;
  ipv4CIDR = addCheckDesc "valid IPv4 address with CIDR suffix" types.str ipaddr.isIPv4CIDR;
  ipv4NoCIDR = addCheckDesc "valid IPv4 address, no CIDR suffix" types.str ipaddr.isIPv4NoCIDR;
  ipv4RFC1918 = addCheckDesc "valid RFC 1918 IPv4 address" types.str ipaddr.isIPv4RFC1918;
  ipv4RFC1918CIDR = addCheckDesc "valid RFC 1918 IPv4 address with CIDR suffix" types.str ipaddr.isIPv4RFC1918CIDR;
  ipv4RFC1918NoCIDR = addCheckDesc "valid RFC 1918 IPv4 address, no CIDR suffix" types.str ipaddr.isIPv4RFC1918NoCIDR;

  ipv6 = addCheckDesc "valid IPv6 address" types.str ipaddr.isIPv6;
  ipv6CIDR = addCheckDesc "valid IPv6 address with CIDR suffix" types.str ipaddr.isIPv6CIDR;
  ipv6NoCIDR = addCheckDesc "valid IPv6 address, no CIDR suffix" types.str ipaddr.isIPv6NoCIDR;

  # The `addrOpts` types should be compatible with many NixOS modules'
  # expectations of an IP address plus subnet prefix.

  addrOptsV4 = types.submodule {
    options = {
      address = mkOption {
        type = ipv4NoCIDR;
        example = "10.8.8.8";
        description = ''
          An IPv4 address (with no CIDR suffix).
        '';
      };
      prefixLength = mkOption {
        type = types.ints.between 1 32;
        example = 32;
        default = 24;
        description = ''
          The IPv4 address's subnet prefix length. The default is
          <literal>24</literal>.
        '';
      };
    };
  };

  addrOptsV6 = types.submodule {
    options = {
      address = mkOption {
        type = ipv6NoCIDR;
        example = "2001:db8::1";
        description = ''
          An IPv6 address (with no CIDR suffix).
        '';
      };
      prefixLength = mkOption {
        type = types.ints.between 1 128;
        default = 64;
        example = 128;
        description = ''
          The IPv6 address's prefix length. The default is
          <literal>64</literal>.
        '';
      };
    };
  };


  ## Integer types.

  # Port 0 is sometimes used to indicate a "don't-care".
  port = types.ints.between 0 65535;
in
rec
{
  lib = (prev.lib or { }) // {
    types = (prev.lib.types or { }) // {
      inherit nonEmptyStr;
      inherit storePath nonStorePath;
      inherit ipv4 ipv4CIDR ipv4NoCIDR ipv4RFC1918 ipv4RFC1918CIDR ipv4RFC1918NoCIDR;
      inherit ipv6 ipv6CIDR ipv6NoCIDR;
      inherit addrOptsV4 addrOptsV6;
      inherit port;
    };
  };
}
