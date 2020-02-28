## Additional useful types, mostly for NixOS modules.

# The key type defined here is based on keyOptionType in NixOps. As it
# is a derivative work of NixOps, it is covered by the GNU LGPL; see
# the LICENSE file included with this source distribution.

self: super:

with super.lib;

let

  ## A key type for configuring secrets that are stored in the
  ## filesystem. The option names and types here are compatible with
  ## NixOps's `keyType`, so they can be mechanically mapped to
  ## `deployment.keys`, but there are a few differences; namely, this
  ## type ensures that its paths are not contained in the Nix store,
  ## so that the chances of accidentally storing a secret in the store
  ## are minimized.

  key = types.submodule ({ config, name, ... }: {
    options.text = mkOption {
      example = "super secret stuff";
      type = super.lib.types.nonEmptyStr;
      description = ''
        This designates the text that the key should contain. So if
        the key name is <replaceable>password</replaceable> and
        <literal>foobar</literal> is set here, the contents of the
        file
        <filename><replaceable>destDir</replaceable>/<replaceable>password</replaceable></filename>
        will be <literal>foobar</literal>.
      '';
    };

    options.destDir = mkOption {
      default = "/run/keys";
      type = super.lib.types.nonStorePath;
      description = ''
        When specified, this allows changing the destDir directory of the key
        file from its default value of <filename>/run/keys</filename>.

        This directory will be created, its permissions changed to
        <literal>0750</literal> and ownership to <literal>root:keys</literal>.
      '';
    };

    options.path = mkOption {
      type = super.lib.types.nonStorePath;
      default = "${config.destDir}/${name}";
      internal = true;
      description = ''
        Path to the destination of the file, a shortcut to
        <literal>destDir</literal> + / + <literal>name</literal>

        Example: For key named <literal>foo</literal>,
        this option would have the value <literal>/run/keys/foo</literal>.
      '';
    };

    options.user = mkOption {
      default = "root";
      type = super.lib.types.nonEmptyStr;
      description = ''
        The user which will be the owner of the key file.
      '';
    };

    options.group = mkOption {
      default = "root";
      type = super.lib.types.nonEmptyStr;
      description = ''
        The group that will be set for the key file.
      '';
    };

    options.permissions = mkOption {
      default = "0400";
      example = "0640";
      type = super.lib.types.nonEmptyStr;
      description = ''
        The default permissions to set for the key file, needs to be in the
        format accepted by <citerefentry><refentrytitle>chmod</refentrytitle>
        <manvolnum>1</manvolnum></citerefentry>.
      '';
    };
  });


  fwRule = types.listOf (types.submodule {
    options = {

      protocol = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "tcp";
        description = ''
          The protocol of the rule or packet to check.
        '';
      };

      interface = mkOption {
        type = types.nullOr super.lib.types.nonEmptyStr;
        default = null;
        example = "eth0";
        description = ''
          An optional device interface name. If non-null, an
          additional filter will be applied, using the interface on
          which packets are received.
        '';
      };

      src = {
        port = mkOption {
          type = types.nullOr (types.either super.lib.types.port (types.strMatching "[[:digit:]]+:[[:digit:]]+"));
          default = null;
          example = "67:68";
          description = ''
            An optional source port number, or colon-delimited port
            number range, to filter on. If non-null, an additional
            filter will be applied using the provided source port
            number.

            This is helpful for securing certain protocols, e.g., DHCP.
          '';
        };

        ip = mkOption {
          type = types.nullOr super.lib.types.ipv4;
          default = null;
          example = "10.0.0.0/24";
          description = ''
            An optional source IP address to filter on.
          '';
        };
      };

      dest = {
        port = mkOption {
          type = types.nullOr (types.either super.lib.types.port (types.strMatching "[[:digit:]]+:[[:digit:]]+"));
          default = null;
          example = "8000:8007";
          description = ''
            An optional destination port number, or colon-delimited port number range.
          '';
        };

        ip = mkOption {
          type = types.nullOr super.lib.types.ipv4;
          default = null;
          example = "10.0.0.0/24";
          description = ''
            An optional destination IP address to filter on.
          '';
        };
      };

    };
  });

  fwRule6 = types.listOf (types.submodule {
    options = {

      protocol = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "tcp";
        description = ''
          The protocol of the rule or packet to check.
        '';
      };

      interface = mkOption {
        type = types.nullOr super.lib.types.nonEmptyStr;
        default = null;
        example = "eth0";
        description = ''
          An optional device interface name. If non-null, an
          additional filter will be applied, using the interface on
          which packets are received.
        '';
      };

      src = {
        port = mkOption {
          type = types.nullOr (types.either super.lib.types.port (types.strMatching "[[:digit:]]+:[[:digit:]]+"));
          default = null;
          example = "67:68";
          description = ''
            An optional source port number, or colon-delimited port
            number range, to filter on. If non-null, an additional
            filter will be applied using the provided source port
            number.

            This is helpful for securing certain protocols, e.g., DHCP.
          '';
        };

        ip = mkOption {
          type = types.nullOr super.lib.types.ipv6;
          default = null;
          example = "2001:db8::3:0/64";
          description = ''
            An optional source IPv6 address to filter on.
          '';
        };
      };

      dest = {
        port = mkOption {
          type = types.nullOr (types.either super.lib.types.port (types.strMatching "[[:digit:]]+:[[:digit:]]+"));
          default = null;
          example = "8000:8007";
          description = ''
            An optional destination port number, or colon-delimited port number range.
          '';
        };

        ip = mkOption {
          type = types.nullOr super.lib.types.ipv6;
          default = null;
          example = "2001:db8::3:0/64";
          description = ''
            An optional destination IPv6 address to filter on.
          '';
        };
      };

    };
  });


  ## An IPv4 subnet description.

  ipv4Subnet = types.submodule {
    options = rec {

      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "The foo subnet";
        description = ''
          An optional one-line description of the subnet.
        '';
      };

      ip = mkOption {
        type = super.lib.types.ipv4CIDR;
        example = "192.168.1.0/24";
        description = ''
          The IPv4 address of the subnet in CIDR notation.
        '';
      };

      prefix = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "192.168.1";
        description = ''
          Just the prefix part of the IPv4 address of the subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      prefixLength = mkOption {
        type = types.ints.between 0 32;
        example = 24;
        description = ''
          Just the prefix length part of the IPv4 address of the
          subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      router = mkOption {
        type = types.nullOr super.lib.types.ipv4NoCIDR;
        example = "192.168.1.1";
        description = ''
          The subnet's default router, expressed as an IPv4 address.

          Technically this attribute is optional; it can be set to
          <literal>null</literal>. This is useful for things like
          point-to-point networks, or networks that should not be
          routed, like inter-router communication networks. However,
          there is no default value, to prevent you from forgetting to
          configure one.
        '';
      };

    };
  };

  dhcp4Subnet = types.submodule {
    options = {

      subnet = mkOption {
        type = ipv4Subnet;
        readOnly = true;
        description = ''
          The descriptor of the IPv4 subnet that will be served.
        '';
      };

      range = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            start = mkOption {
              type = super.lib.types.ipv4NoCIDR;
            };
            end = mkOption {
              type = super.lib.types.ipv4NoCIDR;
            };
          };
        });
        default = null;
        example = {
          start = "192.168.1.200";
          end = "192.168.1.220";
        };
        description = ''
          An optional range of dynamic addresses.
        '';
      };

      leaseTime = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            default = mkOption {
              type = types.ints.unsigned;
            };
            max = mkOption {
              type = types.ints.unsigned;
            };
          };
        });
        default = null;
        example = {
          default = 3600;
          max = 7200;
        };
        description = ''
          An optional default and maximum lease time for this subnet.
        '';
      };

      nameservers = mkOption {
        type = types.listOf (types.either super.lib.types.ipv4NoCIDR super.lib.types.ipv6NoCIDR);
        default = [];
        example = [ "192.168.0.8" "2001:db8::8" ];
        description = ''
          An optional list of IPv4 and IPv6 addresses of nameservers
          for clients on this subnet.
        '';
      };

      deny = mkOption {
        type = types.listOf super.lib.types.nonEmptyStr;
        default = [];
        example = [ "unknown-clients" ];
        description = ''
          An optional list of <literal>dhcpd</literal>
          <literal>deny</literal> directives for this subnet.
        '';
      };

    };
  };

  ## An IPv6 subnet description.

  ipv6Subnet = types.submodule {
    options = rec {

      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "The foo subnet";
        description = ''
          An optional one-line description of the subnet.
        '';
      };

      ip = mkOption {
        type = super.lib.types.ipv6CIDR;
        example = "2001:db8::/64";
        description = ''
          The IPv6 address of the subnet in CIDR notation.
        '';
      };

      prefix = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "2001:db8::";
        description = ''
          Just the prefix part of the IPv6 address of the subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      prefixLength = mkOption {
        type = types.ints.between 0 128;
        example = 64;
        description = ''
          Just the prefix length part of the IPv6 address of the
          subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      router = mkOption {
        type = types.nullOr super.lib.types.ipv6NoCIDR;
        example = "fe80::1";
        description = ''
          The subnet's default router, expressed as an IPv6 address.

          Technically this attribute is optional; it can be set to
          <literal>null</literal>. This is useful for things like
          point-to-point networks, or networks that should not be
          routed, like inter-router communication networks. However,
          there is no default value, to prevent you from forgetting to
          configure one.
        '';
      };

    };
  };

  # A WireGuard peer.

  wgAllowedIP = types.submodule {
    options = {
      ip = mkOption {
        type = types.either super.lib.types.ipv4CIDR super.lib.types.ipv6CIDR;
        example = "10.192.122.3/32";
        description = ''
          An IPv4 or IPv6 address (with CIDR mask) from which this
          peer is allowed to send incoming traffic. The catch-all IPv4
          address <literal>0.0.0.0/0</literal> may be specified for
          all matching IPv4 addresses, and the catch-all IPv6 address
          <literal>::/0</literal> may be specified for matching all
          IPv6 addresses.
        '';
      };

      route = {
        enable = mkEnableOption ''
          a static route for the given IP address via this WireGuard
          device.
        '';

        table = mkOption {
          default = "main";
          example = "vpn";
          type = super.lib.types.nonEmptyStr;
          description = ''
            The kernel routing table to which the static route (if any) will be added.

            The default is the main kernel routing table.
          '';
        };
      };
    };
  };

  wgPeer = types.submodule ({ config, name, ... }: {
    options = {

      name = mkOption {
        type = super.lib.types.nonEmptyStr;
        default = "${name}";
        description = ''
          A short name for the peer. The name should be a valid
          <literal>systemd</literal> service name (i.e., no spaces,
          no special characters, etc.).

          If undefined, the name of the attribute set will be used.
        '';
      };

      publicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = super.lib.types.nonEmptyStr;
        description = "The base64 public key the peer.";
      };

      presharedKeyLiteral = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "<key>";
        description = ''
          The WireGuard pre-shared key for this peer, as a string
          literal, as generated by the command <command>wg
          genpsk</command>. Note that this secret will not be copied
          to the Nix store. However, upon start-up, the service will
          copy a file containing the key to its persistent state
          directory.
       '';
      };

      allowedIPs = mkOption {
        example = literalExample [
          { ip = "10.192.122.3/32"; route.enable = true; }
        ];
        type = types.listOf wgAllowedIP;
        description = ''
          List of IP addresses (and optional routes) for IPs that are
          allowed on this WireGuard interface.
        '';
      };

      endpoint = mkOption {
        default = null;
        example = "demo.wireguard.io:12913";
        type = with types; nullOr str;
        description = ''Endpoint IP or hostname of the peer, followed by a colon,
        and then a port number of the peer.'';
      };

      persistentKeepalive = mkOption {
        default = null;
        type = with types; nullOr int;
        example = 25;
        description = ''This is optional and is by default off, because most
        users will not need it. It represents, in seconds, between 1 and 65535
        inclusive, how often to send an authenticated empty packet to the peer,
        for the purpose of keeping a stateful firewall or NAT mapping valid
        persistently. For example, if the interface very rarely sends traffic,
        but it might at anytime receive traffic from a peer, and it is behind
        NAT, the interface might benefit from having a persistent keepalive
        interval of 25 seconds; however, most users will not need this.'';
      };

    };
  });


  # A remote build host type.
  #
  # This type is mostly compatible with what's expected by the
  # attrsets in the list `nix.buildMachines`. The major difference is
  # that, here, the SSH private key is specified as a literal rather
  # than as a filename, to prevent you from mistakenly putting the
  # file containing the SSH private key into the Nix store.
  #
  # In addition to those attributes, it also provides a list of
  # alternate hostnames and an SSH host key, which are useful for
  # configuring SSH on a build host to guarantee that nix-daemon's
  # initial SSH attempt to log into the remote builder will connect
  # without failing.

  remoteBuildHost = types.submodule {
    options = {

      hostName = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "builder.example.com";
        description = ''
          The primary host name of the remote build host. This is the
          name that should be used in the remote build host's
          `nix.buildMachines` entry.
        '';
      };

      port = mkOption {
        type = types.nullOr super.lib.types.port;
        default = null;
        example = 22;
        description = ''
          An optional TCP port number on which to connect to the
          remote build host. The default value is
          <literal>null</literal>, in which case the default SSH TCP
          port is used (22).

          This option is implemented by adding a
          <literal>Host</literal> stanza to the build host's
          <literal>/etc/ssh/ssh_config</literal> file, because the
          <literal>/etc/nix/machines</literal> file doesn't support
          custom SSH port numbers. This is a bit of a hack, and if you
          need to specify other <literal>/etc/ssh/ssh_config</literal>
          options for this remote build host, you should probably not
          use this option, and instead specify the remote build host's
          custom port number amongst the other SSH configuration
          options for the remote build host, to prevent the
          possibility of conflicts in the
          <literal>/etc/ssh/ssh_config</literal> file.
        '';
      };

      alternateHostNames = mkOption {
        type = types.listOf super.lib.types.nonEmptyStr;
        default = [];
        example = [ "192.168.1.1" "2001:db8::1" ];
        description = ''
          A list of alternate names by which the host is known. At the
          very least, this should include the IPv4 and/or IPv6
          address(es) to which <varname>hostName</varname> resolves, as
          in some situations, <literal>nix-daemon</literal> or Hydra
          will use an IP address rather than a hostname.
        '';
      };

      hostPublicKeyLiteral = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
        description = ''
          A string literal containing the host's SSH public key. This
          can be obtained by running <literal>ssh-keyscan</literal> on
          the host.
        '';
      };

      systems = mkOption {
        type = types.nonEmptyListOf super.lib.types.nonEmptyStr;
        example = [ "x86_64-linux" "i686-linux" ];
        description = ''
          A list of Nix system types for which this remote build host
          can build derivations.
        '';
      };

      maxJobs = mkOption {
        type = types.ints.positive;
        default = 1;
        example = 8;
        description = ''
          The maximum number of jobs to be run in parallel on this
          remote build host.
        '';
      };

      speedFactor = mkOption {
        type = types.ints.positive;
        default = 1;
        example = 2;
        description = ''
          A positive integer whose value represents the remote build
          host's performance, where higher values mean "faster."
        '';
      };

      mandatoryFeatures = mkOption {
        type = types.listOf super.lib.types.nonEmptyStr;
        default = [];
        example = [ "perf" ];
        description = ''
          A list of features that the host must provide.
        '';
      };

      supportedFeatures = mkOption {
        type = types.listOf super.lib.types.nonEmptyStr;
        default = [];
        example = [ "kvm" "big-parallel" ];
        description = ''
          A list of features that the host supports.
        '';
      };

      sshUserName = mkOption {
        type = super.lib.types.nonEmptyStr;
        example = "remote-builder";
        description = ''
          The user name to be used for builds on the remote builder.
          Note that this user must be a member of
          <option>nix.trustedUsers</option> on the remote host.

          Note: this value should be just the bare user name; do not
          include a <literal>ssh://</literal> prefix.
        '';
      };

      sshKeyLiteral = mkOption {
        type = super.lib.types.nonEmptyStr;
        description = ''
          The SSH private key for <varname>sshUser</varname>, as a
          literal string.
        '';
      };
    };
  };

in {
  lib = (super.lib or {}) // {
    types = (super.lib.types or {}) // {
      inherit key;
      inherit fwRule fwRule6;
      inherit ipv4Subnet dhcp4Subnet;
      inherit ipv6Subnet;
      inherit wgAllowedIP wgPeer;
      inherit remoteBuildHost;
    };
  };
}
