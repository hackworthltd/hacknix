{ config
, pkgs
, lib
, ...
}:

let

  cfg = config.networking.virtual-ips;
  enabled = cfg.v4 != [] || cfg.v6 != [];

in
{

  options.networking.virtual-ips.interface = lib.mkOption {
    type = pkgs.lib.types.nonEmptyStr;
    default = "dummy0";
    readOnly = true;
    description = ''
      A read-only attribute that provides the name of the device used
      by the <option>networking.virtual-ips</option> module. This is
      useful so that other modules can programmatically determine the
      name of the interface to which interface the virtual IPs are
      assigned.

      Note that virtual addresses are not automatically routed to this
      host. If you want these addresses to be visible to external
      hosts, you must arrange for them to be routed here.
    '';
  };

  options.networking.virtual-ips.v4 = lib.mkOption {
    type = lib.types.listOf pkgs.lib.types.ipv4NoCIDR;
    default = [];
    example = [ "10.0.0.1" ];
    description = ''
      A list of virtual IPv4 addresses. Each address will be assigned
      to a virtual network device with a /32 subnet prefix.
    '';

  };

  options.networking.virtual-ips.v6 = lib.mkOption {
    type = lib.types.listOf pkgs.lib.types.ipv6NoCIDR;
    default = [];
    example = [ "2001:db8::3" ];
    description = ''
      A list of virtual IPv6 addresses. Each address will be assigned
      to a virtual network device with a /128 subnet prefix.
    '';

  };

  config = lib.mkIf enabled {
    boot.kernelModules = [ "dummy" ];
    networking.interfaces."${cfg.interface}" = {
      ipv4.addresses =
        map (address: { inherit address; prefixLength = 32; }) cfg.v4;
      ipv6.addresses =
        map (address: { inherit address; prefixLength = 128; }) cfg.v6;
    };
  };
}
