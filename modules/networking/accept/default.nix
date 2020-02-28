## Punch holes in the firewall on a protocol/port/IP basis.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.networking.firewall;
  enable = cfg.accept != [] && cfg.enable;

  ipt = cmd: protocol: interface: src: dest:
  let
    sourcePortFilter = optionalString (src.port != null) "--sport ${toString src.port}";
    sourceIPFilter = optionalString (src.ip != null) "--source ${src.ip}";
    destPortFilter = optionalString (dest.port != null) "--dport ${toString dest.port}";
    destIPFilter = optionalString (dest.ip != null) "--destination ${dest.ip}";
    ifFilter = optionalString (interface != null) "-i ${interface}";
  in ''
    ${cmd} -A nixos-fw -p ${protocol} ${ifFilter} ${sourceIPFilter} ${sourcePortFilter} ${destIPFilter} ${destPortFilter} -j nixos-fw-accept
  '';

  extraCommands = ''
    ${concatMapStrings (r: ipt "iptables" r.protocol r.interface r.src r.dest) cfg.accept}
    ${concatMapStrings (r: ipt "ip6tables" r.protocol r.interface r.src r.dest) cfg.accept6}
  '';

in

{

  options.networking.firewall.accept = mkOption {
   type = pkgs.lib.types.fwRule;
   default = [];
   example = [
     { protocol = "tcp";
       dest.port = 22;
       src.ip = "10.0.0.0/24";
     }
     { protocol = "tcp";
       interface = "eth0";
       dest.port = 80;
     }
   ];
   description = ''
     A list of filters that specify which incoming IPv4 packets should
     be accepted by the firewall.

     This option provides finer-grained control than the
     <option>networking.firewall.allowedTCPPorts</option> etc. options
     provide.
   '';
  };

  options.networking.firewall.accept6 = mkOption {
   type = pkgs.lib.types.fwRule6;
   default = [];
   example = [
     { protocol = "tcp";
       src.ip = "2001:db8::/64";
       dest.port = 22;
     }
     { protocol = "tcp";
       interface = "eth0"; 
       dest.port = 80;
     }
   ];
   description = ''
     A list of filters that specify which incoming IPv6 packets should
     be accepted by the firewall.

     This option provides finer-grained control than the
     <option>networking.firewall.allowedTCPPorts</option> etc. options
     provide.
   '';
  };

  config = mkIf enable {
    networking.firewall = { inherit extraCommands; };
  };

}
