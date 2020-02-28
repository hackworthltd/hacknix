## This module improves upon the Nixpkgs module by using better
## typesafety, requiring peer PSKs, and ensuring that PSKs and private
## keys aren't written to the Nix store.
##
## Private keys are automatically generated so that they never need to
## leave the server. The corresponding public key is also generated,
## for use with peers.
##
## It also eliminiates the global table and allowedIPsAsRoutes options
## and moves those to a per-allowed IP setting.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.networking.wireguard-dhess;
  keys = config.hacknix.keychain.keys;

  kernel = config.boot.kernelPackages;

  stateDir = "/var/lib/wireguard";
  keyPath = name: "${stateDir}/wireguard-${name}-key";
  pubKeyPath = name: "${keyPath name}.pub";
  pskName = name: peer: "wireguard-${name}-${peer}-psk";

  # interface options

  interfaceOpts = { name, ... }: {

    options = {

      ips = mkOption {
        example = [ "192.168.2.1/24" "2001:DB8::1:0/112" ];
        default = [];
        type = types.listOf (types.either pkgs.lib.types.ipv4CIDR pkgs.lib.types.ipv6CIDR);
        description = "The IP addresses of the interface.";
      };

      listenPort = mkOption {
        default = null;
        type = with types; nullOr pkgs.lib.types.port;
        example = 51820;
        description = ''
          UDP port for listening. Optional; if not specified,
          automatically generated based on interface name.
        '';
      };

      preSetup = mkOption {
        example = literalExample ''
          ${pkgs.iproute}/bin/ip netns add foo
        '';
        default = "";
        type = with types; coercedTo (listOf str) (concatStringsSep "\n") lines;
        description = ''
          Commands called at the start of the interface setup.
        '';
      };

      postSetup = mkOption {
        example = literalExample ''
          printf "nameserver 10.200.100.1" | ${pkgs.openresolv}/bin/resolvconf -a wg0 -m 0
        '';
        default = "";
        type = with types; coercedTo (listOf str) (concatStringsSep "\n") lines;
        description = "Commands called at the end of the interface setup.";
      };

      postShutdown = mkOption {
        example = literalExample "${pkgs.openresolv}/bin/resolvconf -d wg0";
        default = "";
        type = with types; coercedTo (listOf str) (concatStringsSep "\n") lines;
        description = "Commands called after shutting down the interface.";
      };

      peers = mkOption {
        default = {};
        description = "Peers linked to the interface.";
        type = types.attrsOf pkgs.lib.types.wgPeer;
      };
    };

  };

  generatePathUnit = name: values:
    nameValuePair "wireguard-${name}"
      {
        description = "WireGuard Tunnel - ${name} - Private Key";
        requiredBy = [ "wireguard-${name}.service" ];
        before = [ "wireguard-${name}.service" ];
        pathConfig.PathExists = keyPath name;
      };

  generateKeyServiceUnit = name: values:
    nameValuePair "wireguard-${name}-key"
      {
        description = "WireGuard Tunnel - ${name} - Key Generator";
        wantedBy = [ "wireguard-${name}.service" ];
        requiredBy = [ "wireguard-${name}.service" ];
        before = [ "wireguard-${name}.service" ];
        path = with pkgs; [ wireguard ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script =
        let
          keyFile = keyPath name;
          pubKeyFile = pubKeyPath name;
        in
        ''
          if [ ! -f "${keyFile}" ]; then
            touch "${keyFile}"
            chmod 0600 "${keyFile}"
            wg genkey > "${keyFile}"
            chmod 0400 "${keyFile}"
            touch "${pubKeyFile}"
            chmod 644 "${pubKeyFile}"
            cat "${keyFile}" | wg pubkey > "${pubKeyFile}"
          fi
        '';
      };

  generateSetupServiceUnit = name: values:
  let
    peers = mapAttrsToList (_: peer: peer) values.peers;
  in
    nameValuePair "wireguard-${name}"
      rec {
        description = "WireGuard Tunnel - ${name}";
        wants = map (peer: "${pskName name peer.name}-key.service") peers;
        requires = [ "network-online.target" ];
        after = [ "network.target" "network-online.target" ] ++ wants;
        wantedBy = [ "multi-user.target" ];
        environment.DEVICE = name;
        environment.WG_ENDPOINT_RESOLUTION_RETRIES = "infinity";
        path = with pkgs; [ kmod iproute wireguard-tools ];

        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = "5s";
          RemainAfterExit = true;
        };

        script =
        let
          keyFile = keyPath name;
        in
        ''
	        ${optionalString (!config.boot.isContainer) "modprobe wireguard || true"}

          ${values.preSetup}

          ip link add dev ${name} type wireguard

          ${concatMapStringsSep "\n" (ip:
            "ip address add ${ip} dev ${name}"
          ) values.ips}

          wg set ${name} private-key ${keyFile} ${
            optionalString (values.listenPort != null) " listen-port ${toString values.listenPort}"}

          ${concatMapStringsSep "\n" (peer:
            let
              pskPath = keys."${pskName name peer.name}".path;
              allowedIPs = map (allowedIP: allowedIP.ip) peer.allowedIPs;
            in
              "wg set ${name} peer ${peer.publicKey}" +
              " preshared-key ${pskPath}" +
              optionalString (peer.endpoint != null) " endpoint ${peer.endpoint}" +
              optionalString (peer.persistentKeepalive != null) " persistent-keepalive ${toString peer.persistentKeepalive}" +
              optionalString (allowedIPs != []) " allowed-ips ${concatStringsSep "," allowedIPs}"
            ) peers}

          ip link set up dev ${name}

          ${concatMapStringsSep "\n"
              (peer:
                concatMapStringsSep
                  "\n"
                  (allowedIP:
                    optionalString allowedIP.route.enable "ip route replace ${allowedIP.ip} dev ${name} table ${allowedIP.route.table}")
                  peer.allowedIPs)
              peers}

          ${values.postSetup}
        '';

        postStop = ''
          ip link del dev ${name}
          ${values.postShutdown}
        '';
      };

in

{

  ###### interface

  options = {

    networking.wireguard-dhess = {

      interfaces = mkOption {
        description = "Wireguard interfaces.";
        default = {};
        example = {
          wg0 = {
            ips = [ "192.168.20.4/24" ];
            peers.demo =
              { allowedIPs = [ "192.168.20.1/32" ];
                presharedKeyLiteral = "tSOLSmehg25TvZghw4R2uIgDrkXh0PEvDupZcXrRNEc=";
                publicKey  = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
                endpoint   = "demo.wireguard.io:12913"; };
          };
        };
        type = with types; attrsOf (submodule interfaceOpts);
      };

    };

  };


  ###### implementation

  config = mkIf (cfg.interfaces != {}) {

    hacknix.assertions.moduleHashes."services/networking/wireguard.nix" =
      "d894683e0e4b91ad8327adf56e6422afd058bd541efad8a116e9289a8884206c";

    boot.extraModulePackages = [ kernel.wireguard ];
    environment.systemPackages = [ pkgs.wireguard-tools ];

    systemd.tmpfiles.rules = [
      "d '${stateDir}' 0750 root keys - -"
    ];

    systemd.services = (mapAttrs' generateSetupServiceUnit cfg.interfaces)
      // (mapAttrs' generateKeyServiceUnit cfg.interfaces);

    systemd.paths = mapAttrs' generatePathUnit cfg.interfaces;

    hacknix.keychain.keys = listToAttrs (filter (x: x.value != null) (
      lib.flatten
        (mapAttrsToList
          (ifname: values:
            mapAttrsToList
              (peer: values: nameValuePair (pskName ifname peer) ({
                destDir = stateDir;
                text = values.presharedKeyLiteral;
              }))
              values.peers)
          cfg.interfaces)
      ));

  };

}
