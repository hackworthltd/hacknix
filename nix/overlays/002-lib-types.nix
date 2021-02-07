# # Additional useful types, mostly for NixOS modules.

# The key type defined here is based on keyOptionType in NixOps. As it
# is a derivative work of NixOps, it is covered by the GNU LGPL; see
# the LICENSE file included with this source distribution.

final: prev:
let
  ## A key type for configuring secrets that are stored in the
  ## filesystem. The option names and types here are compatible with
  ## NixOps's `keyType`, so they can be mechanically mapped to
  ## `deployment.keys`, but there are a few differences; namely, this
  ## type ensures that its paths are not contained in the Nix store,
  ## so that the chances of accidentally storing a secret in the store
  ## are minimized.
  key = final.lib.types.submodule
    (
      { config, name, ... }: {
        options.text = final.lib.mkOption {
          example = "secret stuff";
          type = final.lib.types.nonEmptyStr;
          description = ''
            This designates the text that the key should contain. So if
            the key name is <replaceable>password</replaceable> and
            <literal>foobar</literal> is set here, the contents of the
            file
            <filename><replaceable>destDir</replaceable>/<replaceable>password</replaceable></filename>
            will be <literal>foobar</literal>.
          '';
        };

        options.destDir = final.lib.mkOption {
          default = "/run/keys";
          type = final.lib.types.nonStorePath;
          description = ''
            When specified, this allows changing the destDir directory of the key
            file from its default value of <filename>/run/keys</filename>.

            This directory will be created, its permissions changed to
            <literal>0750</literal> and ownership to <literal>root:keys</literal>.
          '';
        };

        options.path = final.lib.mkOption {
          type = final.lib.types.nonStorePath;
          default = "${config.destDir}/${name}";
          internal = true;
          description = ''
            Path to the destination of the file, a shortcut to
            <literal>destDir</literal> + / + <literal>name</literal>

            Example: For key named <literal>foo</literal>,
            this option would have the value <literal>/run/keys/foo</literal>.
          '';
        };

        options.user = final.lib.mkOption {
          default = "root";
          type = final.lib.types.nonEmptyStr;
          description = ''
            The user which will be the owner of the key file.
          '';
        };

        options.group = final.lib.mkOption {
          default = "root";
          type = final.lib.types.nonEmptyStr;
          description = ''
            The group that will be set for the key file.
          '';
        };

        options.permissions = final.lib.mkOption {
          default = "0400";
          example = "0640";
          type = final.lib.types.nonEmptyStr;
          description = ''
            The default permissions to set for the key file, needs to be in the
            format accepted by <citerefentry><refentrytitle>chmod</refentrytitle>
            <manvolnum>1</manvolnum></citerefentry>.
          '';
        };
      }
    );
  fwRule = final.lib.types.listOf
    (
      final.lib.types.submodule {
        options = {

          protocol = final.lib.mkOption {
            type = final.lib.types.nonEmptyStr;
            example = "tcp";
            description = ''
              The protocol of the rule or packet to check.
            '';
          };

          interface = final.lib.mkOption {
            type = final.lib.types.nullOr final.lib.types.nonEmptyStr;
            default = null;
            example = "eth0";
            description = ''
              An optional device interface name. If non-null, an
              additional filter will be applied, using the interface on
              which packets are received.
            '';
          };

          src = {
            port = final.lib.mkOption {
              type = final.lib.types.nullOr
                (
                  final.lib.types.either final.lib.types.port
                    (final.lib.types.strMatching "[[:digit:]]+:[[:digit:]]+")
                );
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

            ip = final.lib.mkOption {
              type = final.lib.types.nullOr final.lib.types.ipv4;
              default = null;
              example = "10.0.0.0/24";
              description = ''
                An optional source IP address to filter on.
              '';
            };
          };

          dest = {
            port = final.lib.mkOption {
              type = final.lib.types.nullOr
                (
                  final.lib.types.either final.lib.types.port
                    (final.lib.types.strMatching "[[:digit:]]+:[[:digit:]]+")
                );
              default = null;
              example = "8000:8007";
              description = ''
                An optional destination port number, or colon-delimited port number range.
              '';
            };

            ip = final.lib.mkOption {
              type = final.lib.types.nullOr final.lib.types.ipv4;
              default = null;
              example = "10.0.0.0/24";
              description = ''
                An optional destination IP address to filter on.
              '';
            };
          };

        };
      }
    );
  fwRule6 = final.lib.types.listOf
    (
      final.lib.types.submodule {
        options = {

          protocol = final.lib.mkOption {
            type = final.lib.types.nonEmptyStr;
            example = "tcp";
            description = ''
              The protocol of the rule or packet to check.
            '';
          };

          interface = final.lib.mkOption {
            type = final.lib.types.nullOr final.lib.types.nonEmptyStr;
            default = null;
            example = "eth0";
            description = ''
              An optional device interface name. If non-null, an
              additional filter will be applied, using the interface on
              which packets are received.
            '';
          };

          src = {
            port = final.lib.mkOption {
              type = final.lib.types.nullOr
                (
                  final.lib.types.either final.lib.types.port
                    (final.lib.types.strMatching "[[:digit:]]+:[[:digit:]]+")
                );
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

            ip = final.lib.mkOption {
              type = final.lib.types.nullOr final.lib.types.ipv6;
              default = null;
              example = "2001:db8::3:0/64";
              description = ''
                An optional source IPv6 address to filter on.
              '';
            };
          };

          dest = {
            port = final.lib.mkOption {
              type = final.lib.types.nullOr
                (
                  final.lib.types.either final.lib.types.port
                    (final.lib.types.strMatching "[[:digit:]]+:[[:digit:]]+")
                );
              default = null;
              example = "8000:8007";
              description = ''
                An optional destination port number, or colon-delimited port number range.
              '';
            };

            ip = final.lib.mkOption {
              type = final.lib.types.nullOr final.lib.types.ipv6;
              default = null;
              example = "2001:db8::3:0/64";
              description = ''
                An optional destination IPv6 address to filter on.
              '';
            };
          };

        };
      }
    );

  ## An IPv4 subnet description.
  ipv4Subnet = final.lib.types.submodule {
    options = rec {

      description = final.lib.mkOption {
        type = final.lib.types.nullOr final.lib.types.str;
        default = null;
        example = "The foo subnet";
        description = ''
          An optional one-line description of the subnet.
        '';
      };

      ip = final.lib.mkOption {
        type = final.lib.types.ipv4CIDR;
        example = "192.168.1.0/24";
        description = ''
          The IPv4 address of the subnet in CIDR notation.
        '';
      };

      prefix = final.lib.mkOption {
        type = final.lib.types.nonEmptyStr;
        example = "192.168.1";
        description = ''
          Just the prefix part of the IPv4 address of the subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      prefixLength = final.lib.mkOption {
        type = final.lib.types.ints.between 0 32;
        example = 24;
        description = ''
          Just the prefix length part of the IPv4 address of the
          subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      router = final.lib.mkOption {
        type = final.lib.types.nullOr final.lib.types.ipv4NoCIDR;
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
  dhcp4Subnet = final.lib.types.submodule {
    options = {

      subnet = final.lib.mkOption {
        type = ipv4Subnet;
        readOnly = true;
        description = ''
          The descriptor of the IPv4 subnet that will be served.
        '';
      };

      range = final.lib.mkOption {
        type = final.lib.types.nullOr
          (
            final.lib.types.submodule {
              options = {
                start = final.lib.mkOption { type = final.lib.types.ipv4NoCIDR; };
                end = final.lib.mkOption { type = final.lib.types.ipv4NoCIDR; };
              };
            }
          );
        default = null;
        example = {
          start = "192.168.1.200";
          end = "192.168.1.220";
        };
        description = ''
          An optional range of dynamic addresses.
        '';
      };

      leaseTime = final.lib.mkOption {
        type = final.lib.types.nullOr
          (
            final.lib.types.submodule {
              options = {
                default = final.lib.mkOption { type = final.lib.types.ints.unsigned; };
                max = final.lib.mkOption { type = final.lib.types.ints.unsigned; };
              };
            }
          );
        default = null;
        example = {
          default = 3600;
          max = 7200;
        };
        description = ''
          An optional default and maximum lease time for this subnet.
        '';
      };

      nameservers = final.lib.mkOption {
        type = final.lib.types.listOf
          (final.lib.types.either final.lib.types.ipv4NoCIDR final.lib.types.ipv6NoCIDR);
        default = [ ];
        example = [ "192.168.0.8" "2001:db8::8" ];
        description = ''
          An optional list of IPv4 and IPv6 addresses of nameservers
          for clients on this subnet.
        '';
      };

      deny = final.lib.mkOption {
        type = final.lib.types.listOf final.lib.types.nonEmptyStr;
        default = [ ];
        example = [ "unknown-clients" ];
        description = ''
          An optional list of <literal>dhcpd</literal>
          <literal>deny</literal> directives for this subnet.
        '';
      };

      extraConfig = final.lib.mkOption {
        type = final.lib.types.lines;
        default = "";
        example = final.lib.literalExample ''
          option ubnt.unifi-address 192.168.0.8;
        '';
        description = ''
          Optional additional configuration for the
          <literal>dhcpd</literal> subnet.
        '';
      };
    };
  };

  ## An IPv6 subnet description.
  ipv6Subnet = final.lib.types.submodule {
    options = rec {

      description = final.lib.mkOption {
        type = final.lib.types.nullOr final.lib.types.str;
        default = null;
        example = "The foo subnet";
        description = ''
          An optional one-line description of the subnet.
        '';
      };

      ip = final.lib.mkOption {
        type = final.lib.types.ipv6CIDR;
        example = "2001:db8::/64";
        description = ''
          The IPv6 address of the subnet in CIDR notation.
        '';
      };

      prefix = final.lib.mkOption {
        type = final.lib.types.nonEmptyStr;
        example = "2001:db8::";
        description = ''
          Just the prefix part of the IPv6 address of the subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      prefixLength = final.lib.mkOption {
        type = final.lib.types.ints.between 0 128;
        example = 64;
        description = ''
          Just the prefix length part of the IPv6 address of the
          subnet.

          <em>Note: this should be calculated automatically, but
          currently it is not.</em>
        '';
      };

      router = final.lib.mkOption {
        type = final.lib.types.nullOr final.lib.types.ipv6NoCIDR;
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
  wgAllowedIP = final.lib.types.submodule {
    options = {
      ip = final.lib.mkOption {
        type = final.lib.types.either final.lib.types.ipv4CIDR final.lib.types.ipv6CIDR;
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
        enable = final.lib.mkEnableOption ''
          a static route for the given IP address via this WireGuard
          device.
        '';

        table = final.lib.mkOption {
          default = "main";
          example = "vpn";
          type = final.lib.types.nonEmptyStr;
          description = ''
            The kernel routing table to which the static route (if any) will be added.

            The default is the main kernel routing table.
          '';
        };
      };
    };
  };
  wgPeer = final.lib.types.submodule
    (
      { config, name, ... }: {
        options = {

          name = final.lib.mkOption {
            type = final.lib.types.nonEmptyStr;
            default = "${name}";
            description = ''
              A short name for the peer. The name should be a valid
              <literal>systemd</literal> service name (i.e., no spaces,
              no special characters, etc.).

              If undefined, the name of the attribute set will be used.
            '';
          };

          publicKey = final.lib.mkOption {
            example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
            type = final.lib.types.nonEmptyStr;
            description = "The base64 public key the peer.";
          };

          presharedKeyLiteral = final.lib.mkOption {
            type = final.lib.types.nonEmptyStr;
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

          allowedIPs = final.lib.mkOption {
            example = final.lib.literalExample [
              {
                ip = "10.192.122.3/32";
                route.enable = true;
              }
            ];
            type = final.lib.types.listOf wgAllowedIP;
            description = ''
              List of IP addresses (and optional routes) for IPs that are
              allowed on this WireGuard interface.
            '';
          };

          endpoint = final.lib.mkOption {
            default = null;
            example = "demo.wireguard.io:12913";
            type = with final.lib.types; nullOr str;
            description = ''
              Endpoint IP or hostname of the peer, followed by a colon,
                      and then a port number of the peer.'';
          };

          persistentKeepalive = final.lib.mkOption {
            default = null;
            type = with final.lib.types; nullOr int;
            example = 25;
            description = ''
              This is optional and is by default off, because most
                      users will not need it. It represents, in seconds, between 1 and 65535
                      inclusive, how often to send an authenticated empty packet to the peer,
                      for the purpose of keeping a stateful firewall or NAT mapping valid
                      persistently. For example, if the interface very rarely sends traffic,
                      but it might at anytime receive traffic from a peer, and it is behind
                      NAT, the interface might benefit from having a persistent keepalive
                      interval of 25 seconds; however, most users will not need this.'';
          };

        };
      }
    );

  # A remote build host type.
  #
  # This type is mostly compatible with what's expected by the
  # attrsets in the list `nix.buildMachines`. The major difference is
  # that, here, the (optional) SSH private key is specified as a
  # literal rather than as a filename, to prevent you from mistakenly
  # putting the file containing the SSH private key into the Nix
  # store.
  #
  # In addition to those attributes, it also provides a list of
  # alternate hostnames and an SSH host key, which are useful for
  # configuring SSH on a build host to guarantee that nix-daemon's
  # initial SSH attempt to log into the remote builder will connect
  # without failing. It also allows you to provide a list of public
  # SSH keys that can be used to authenticate as the remote build
  # user.
  remoteBuildHost = final.lib.types.submodule {
    options = {

      hostName = final.lib.mkOption {
        type = final.lib.types.nonEmptyStr;
        example = "builder.example.com";
        description = ''
          The primary host name of the remote build host. This is the
          name that should be used in the remote build host's
          `nix.buildMachines` entry.
        '';
      };

      port = final.lib.mkOption {
        type = final.lib.types.nullOr final.lib.types.port;
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

      alternateHostNames = final.lib.mkOption {
        type = final.lib.types.listOf final.lib.types.nonEmptyStr;
        default = [ ];
        example = [ "192.168.1.1" "2001:db8::1" ];
        description = ''
          A list of alternate names by which the host is known. At the
          very least, this should include the IPv4 and/or IPv6
          address(es) to which <varname>hostName</varname> resolves, as
          in some situations, <literal>nix-daemon</literal> or Hydra
          will use an IP address rather than a hostname.
        '';
      };

      hostPublicKeyLiteral = final.lib.mkOption {
        type = final.lib.types.nonEmptyStr;
        example =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
        description = ''
          A string literal containing the host's SSH public key. This
          can be obtained by running <literal>ssh-keyscan</literal> on
          the host.
        '';
      };

      systems = final.lib.mkOption {
        type = final.lib.types.nonEmptyListOf final.lib.types.nonEmptyStr;
        example = [ "x86_64-linux" "i686-linux" ];
        description = ''
          A list of Nix system types for which this remote build host
          can build derivations.
        '';
      };

      maxJobs = final.lib.mkOption {
        type = final.lib.types.ints.positive;
        default = 1;
        example = 8;
        description = ''
          The maximum number of jobs to be run in parallel on this
          remote build host.
        '';
      };

      speedFactor = final.lib.mkOption {
        type = final.lib.types.ints.positive;
        default = 1;
        example = 2;
        description = ''
          A positive integer whose value represents the remote build
          host's performance, where higher values mean "faster."
        '';
      };

      mandatoryFeatures = final.lib.mkOption {
        type = final.lib.types.listOf final.lib.types.nonEmptyStr;
        default = [ ];
        example = [ "perf" ];
        description = ''
          A list of features that the host must provide.
        '';
      };

      supportedFeatures = final.lib.mkOption {
        type = final.lib.types.listOf final.lib.types.nonEmptyStr;
        default = [ ];
        example = [ "kvm" "big-parallel" ];
        description = ''
          A list of features that the host supports.
        '';
      };

      sshUserName = final.lib.mkOption {
        type = final.lib.types.nonEmptyStr;
        example = "remote-builder";
        description = ''
          The user name to be used for builds on the remote builder.
          Note that this user must be a member of
          <option>nix.trustedUsers</option> on the remote host.

          Note: this value should be just the bare user name; do not
          include a <literal>ssh://</literal> prefix.
        '';
      };

      sshUserPublicKeys = final.lib.mkOption {
        type = final.lib.types.listOf final.lib.types.nonEmptyStr;
        default = [ ];
        example = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAL9hxC4bYdA70iI8pDA7T5x55dQa9Ox3u0upJ24XMxk" ];
        description = ''
          An optional list of public keys that can be used by remote
          users/services to authenticate as the remote build user.
        '';
      };

      sshKeyLiteral = final.lib.mkOption {
        type = final.lib.types.nullOr final.lib.types.nonEmptyStr;
        default = null;
        description = ''
          An optional SSH private key for <varname>sshUser</varname>,
          as a literal string.
        '';
      };
    };
  };
in
{
  lib = (prev.lib or { }) // {
    types = (prev.lib.types or { }) // {
      inherit key;
      inherit fwRule fwRule6;
      inherit ipv4Subnet dhcp4Subnet;
      inherit ipv6Subnet;
      inherit wgAllowedIP wgPeer;
      inherit remoteBuildHost;
    };
  };
}
