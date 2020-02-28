# Configure a network interface for high-speed packet capture.
#
# Most of the dirty tricks employed by this service come from the
# following sources:
#
# http://blog.securityonion.net/2011/10/when-is-full-packet-capture-not-full.html
# http://mailman.icsi.berkeley.edu/pipermail/bro/2017-January/011280.html
# https://groups.google.com/forum/#!topic/security-onion/1nW4M4zD9D4
# https://github.com/pevma/SEPTun
# https://github.com/Security-Onion-Solutions/securityonion-nsmnow-admin-scripts/blob/21e36844409f8b863b4558912aefc085283fb408/usr/sbin/nsm_sensor_ps-start#L466
#
# Note that we do not pin interrupts to a particular CPU here. Most
# high-performance packet capture apps can already do that.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.pcap-prep;
  interfacesList = mapAttrsToList (_: config: config) cfg.interfaces;

in
{
  options = {
    services.pcap-prep = {

      interfaces = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: (import ./interface-options.nix {
          inherit name config lib pkgs;
        })));
        default = {};
        example = literalExample ''
          eno3 = {
            rxRingEntries = 512;
            usecBetweenRxInterrupts = 100;
          };
        '';
        description = ''
          For each network interface configured here, a one-shot service
          will be run at network bring-up time which configures the
          interface for high-speed network catpure. It does this by
          disabling all hardware offloading features, configuring a
          single RX queue, disabling pause frames, disabling ARP, etc.

          It will also disable DHCP and IPv6 on the interface. (Disabling
          IPv6 is necessary so that no SLAAC or link-local addresses
          will be configured. Note that this has no effect on the
          ability to capture IPv6 packets that appear on the interface.)

          Note that this service does <em>not</em> put the interface in
          promiscuous mode. It is expected that any services capturing
          packets on this interface will do that, if needed.
        '';
      };
    };

  };

  config = mkIf (cfg.interfaces != {}) {

    networking.interfaces = listToAttrs (filter (x: x.value != null) (
      (mapAttrsToList
        (_: conf: nameValuePair "${conf.name}" ({

          useDHCP = false;

        })) cfg.interfaces)
    ));

    systemd.services = listToAttrs (filter (x: x.value != null) (
      (mapAttrsToList
        (_: conf: nameValuePair "pcap-prep-${conf.name}" ({

          description = "Configure ${conf.name} for packet capture";
          wantedBy = [ "network.target" ];
          before = [ "network.target" ];
          script = ''
            ${pkgs.iproute}/bin/ip link set ${conf.name} arp off

            ${pkgs.tsoff}/bin/tsoff ${conf.name}

            # The following command will fail if no changes are made,
            # so we must accept failure.
            ${pkgs.ethtool}/bin/ethtool -G ${conf.name} rx ${toString conf.rxRingEntries} || true

            ${pkgs.ethtool}/bin/ethtool -L ${conf.name} combined 1
            ${pkgs.ethtool}/bin/ethtool -A ${conf.name} rx off tx off
            ${pkgs.ethtool}/bin/ethtool -C ${conf.name} adaptive-rx on rx-usecs ${toString conf.usecBetweenRxInterrupts}
            echo 1 > /proc/sys/net/ipv6/conf/${conf.name}/disable_ipv6
          '';
        })) cfg.interfaces)
    ));

  };
}
