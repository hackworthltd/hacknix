# An opinionated unbound that supports multiple instances.
#
# Note: do NOT set networking.resolvconf.useLocalResolver to true
# here.

{ config, pkgs, lib, ... }:

with lib;

let

  globalCfg = config;
  instances = globalCfg.services.unbound-multi-instance.instances;

  stateDir = "/var/lib/unbound-multi-instance";


  wrapped = runCommand "ipfs" { buildInputs = [ makeWrapper ]; preferLocalBuild = true; } ''
    mkdir -p "$out/bin"
    makeWrapper "${ipfs}/bin/ipfs" "$out/bin/ipfs" \
      --set IPFS_PATH ${cfg.dataDir} \
      --prefix PATH : /run/wrappers/bin
  '';

  mkServiceName = name: "unbound-${name}";

  mkUnboundService = name: cfg:
  let
    isLocalAddress = x: substring 0 3 x == "::1" || substring 0 9 x == "127.0.0.1";
    rootTrustAnchorFile = "${stateDir}/root.key";
    confFileName = "unbound-${name}.conf";
    confFile = pkgs.writeText confFileName ''
      server:
        directory: "${stateDir}"
        username: unbound
        chroot: "${stateDir}"
        pidfile: ""
        num-threads: ${toString cfg.numThreads}
        tls-cert-bundle: ${cfg.tlsCertBundle}
        ${concatMapStringsSep "\n  " (ip: "interface: ${ip}") cfg.listenAddresses}
        ${concatMapStringsSep "\n  " (cidr: "access-control: ${cidr} allow") cfg.allowedAccess}
        ${optionalString cfg.enableRootTrustAnchor "auto-trust-anchor-file: ${rootTrustAnchorFile}"}

      unwanted-reply-threshold: 10000000

      verbosity: 3
      prefetch: yes
      prefetch-key: yes

      hide-version: yes
      hide-identity: yes

      private-address: 10.0.0.0/8
      private-address: 172.16.0.0/12
      private-address: 192.168.0.0/16
      private-address: 169.254.0.0/16
      private-address: fd00::/8
      private-address: fe80::/10

      ${cfg.extraConfig}
      ${optionalString (any isLocalAddress cfg.forwardAddresses) ''
          do-not-query-localhost: no
        '' +
        optionalString (cfg.forwardAddresses != []) ''
          forward-zone:
            name: .
            ${optionalString cfg.dnsOverTLS "forward-tls-upstream: yes"}
        '' +
        concatMapStringsSep "\n" (x: "    forward-addr: ${x}") cfg.forwardAddresses}
    '';
  in nameValuePair (mkServiceName name)
  {
    description = "Unbound recursive name server (multi-instance)";
    after = [ "network.target" ];
    before = [ "nss-lookup.target" ];
    wants = [ "nss-lookup.target" ];
    wantedBy = [ "multi-user.target" ];

    preStart = ''
      mkdir -m 0755 -p ${stateDir}/dev/
      cp ${confFile} ${stateDir}/${confFileName}
      ${optionalString cfg.enableRootTrustAnchor ''
        ${pkgs.unbound}/bin/unbound-anchor -a ${rootTrustAnchorFile} || echo "Root anchor updated!"
        chown unbound ${stateDir} ${rootTrustAnchorFile}
      ''}
      touch ${stateDir}/dev/random
      ${pkgs.utillinux}/bin/mount --bind -n /dev/urandom ${stateDir}/dev/random
    '';

    serviceConfig = {
      ExecStart = "${pkgs.unbound}/bin/unbound -d -c ${stateDir}/${confFileName}";
      ExecStopPost="${pkgs.utillinux}/bin/umount ${stateDir}/dev/random";

      ProtectSystem = true;
      ProtectHome = true;
      PrivateDevices = true;
      Restart = "always";
      RestartSec = "5s";
    };
  };

in {

  options.services.unbound-multi-instance = {

    instances = mkOption {
      description = ''
        Zero or more Unbound service instances.
      '';
      default = {};
      example = literalExample {
        adblock = {
          allowedAccess = [ "10.0.0.0/8" ];
          listenAddresses = [ "10.8.8.8" "2001:db8::1" ];
          extraConfig = builtins.readFile "${pkgs.badhosts-unified}/unbound.conf";
        };
      };
      type = types.attrsOf (types.submodule {
        options = {
          numThreads = mkOption {
            type = types.ints.positive;
            default = 1;
            example = 2;
            description = ''
              How many threads the service should run.
            '';
          };

          allowedAccess = mkOption {
            default = [ "127.0.0.0/8" "::1" ];
            example = [ "192.168.1.0/24" "2001:db8::/64"];
            type = types.listOf (types.either pkgs.lib.types.ipv4CIDR pkgs.lib.types.ipv6CIDR);
            description = ''
              A list of networks that can use this instance as a
              resolver, in CIDR notation.

              Note that this setting does not alter any firewall
              settings; it is only an application-level access list.
            '';
          };

          listenAddresses = mkOption {
            type = types.nonEmptyListOf (types.either pkgs.lib.types.ipv4NoCIDR pkgs.lib.types.ipv6NoCIDR);
            example = [ "10.8.8.8" "2001:db8::1" ];
            description = ''
              A list of IPv4 and/or IPv6 addresses on which this
              Unbound instance will listen. Note that no more than one
              instance can listen on any given unique address.

              At least one address must be provided.
            '';
          };

          tlsCertBundle = mkOption {
            type = types.path;
            default = "${pkgs.cacert.out}/etc/ssl/certs/ca-bundle.crt";
            example = "/etc/ssl/certs/ca-bundle.crt";
            description = ''
              Unbound's <literal>tls-cert-bundle</literal> setting; used for
              authenticating connections to outside peers, e.g., for DNS
              over TLS connections.
            '';
          };

          dnsOverTLS = mkEnableOption ''
            DNS over TLS. Note that this requires the
            use of forwarding addresses that support DNS over TLS.
          '';

          forwardAddresses = mkOption {
            example = [ "8.8.8.8" "2001:4860:4860::8888" ];
            type = types.nonEmptyListOf pkgs.lib.types.nonEmptyStr;
            description = ''
              The address(es) of forwarding servers for this Unbound
              instance. Both IPv4 and IPv6 addresses are supported.
            '';
          };

          enableRootTrustAnchor = mkOption {
            default = true;
            type = types.bool;
            description = "Use and update root trust anchor for DNSSEC validation on this Unbound instance.";
          };

          extraConfig = mkOption {
            default = "";
            type = types.lines;
            description = "Extra Unbound config for this instance.";
          };
        };
      });
    };

  };

  config = mkIf (instances != {}) {

    assertions = [
      { assertion = !globalCfg.services.unbound.enable;
        message = "Only one of `services.unbound` and `services.unbound-multi-instance` can be enabled.";
      }
    ];

    # Track changes in upstream service, in case we need to reproduce
    # them here.

    hacknix.assertions.moduleHashes."services/networking/unbound.nix" =
      "8af6d702a2abe945c90054e7233ca908994eaab59781f364f1f34e7533d5462d";

    environment.systemPackages = [ pkgs.unbound ];

    users.users.unbound = {
      description = "unbound daemon user";
      isSystemUser = true;
    };


    systemd.services =
      mapAttrs' mkUnboundService instances;

  };

  meta.maintainers = lib.maintainers.dhess;

}
