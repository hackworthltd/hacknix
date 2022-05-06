##
## XXX TODO dhess:
## - chroot
## - SendReports

{ config, lib, pkgs, ... }:

with lib;
let
  opendkimEnabled = config.services.opendkim.enable;
  cfg = config.services.qx-opendkim;
  keyTableRow = types.submodule
    (
      { name, ... }: {
        options = {
          keyName = mkOption {
            type = pkgs.lib.types.nonEmptyStr;
            example = "drewhess.com";
            default = "${name}";
            description = ''
              The logical name of the key; to be used in a signing table.

              The default value is the name of the attrset.
            '';
          };

          domain = mkOption {
            type = pkgs.lib.types.nonEmptyStr;
            example = "drewhess.com";
            description = ''
              The domain name to use in the signature's
              <literal>d=</literal> value.
            '';
          };

          selector = mkOption {
            type = pkgs.lib.types.nonEmptyStr;
            example = "2018.10.27";
            description = ''
              The name of the selector to use in the signature's
              <literal>s=</literal> value.
            '';
          };

          privateKeyFile = mkOption {
            type = pkgs.lib.types.nonStorePath;
            example = "/var/lib/opendkim/example.com.key";
            description = ''
              A path to the file containing the private key used to
              sign the signature for this domain.
            '';
          };
        };
      }
    );
  signingTableRow = types.submodule {
    options = {
      fromRegex = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "*@drewhess.com";
        description = ''
          A regular expression used to search the
          <literal>From:</literal> header of an incoming message. If
          the header matches this regex, the key name given in this
          row (see the <literal>keyName</literal> option) is looked up
          in the key table, and that key is used to sign the message.
        '';
      };

      keyName = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "drewhess";
        description = ''
          The logical name of the key used to sign an incoming message
          that matches this row. Note that a key by this name must be
          present in the OpenDKIM key table. (See the
          <literal>keyTable</literal> option.)
        '';
      };
    };
  };

  # Note that this file doesn't contain any key material, only paths
  # to files containing key material.
  keyTableFile = pkgs.writeText "opendkim.key.table"
    (
      concatMapStringsSep "\n"
        (row: "${row.keyName}    ${row.domain}:${row.selector}:${row.privateKeyFile}")
        (mapAttrsToList (_: row: row) cfg.keyTable)
    );
  signingTableFile = pkgs.writeText "opendkim.signing.table"
    (
      concatMapStringsSep "\n" (row: "${row.fromRegex}    ${row.keyName}")
        cfg.signingTable
    );
  internalHostsFile = pkgs.writeText "opendkim.internal.hosts"
    (concatStringsSep "\n" cfg.internalHosts);

  # Notes on our configuration:
  #
  # We always oversign From (sign using actual From) to prevent
  # malicious signatures header fields (From and/or others) between
  # the signer and the verifier. This is per Debian configuration, as
  # From is often the identity key used by reputation systems and thus
  # somewhat security sensitive.
  #
  # Set MustBeSigned according to RFC 4871 (From header only).
  #
  # Set SignatureTTL to 1 week.
  #
  # Use simple/relaxed canonicalization, so that body whitespace
  # manipulations by MTAs don't break signatures.
  #
  # Add Sender to SenderHeaders so that local mailing list messages
  # are signed.
  configFile = pkgs.writeText "opendkim.conf" ''
    UMask            002
    OversignHeaders  From
    Canonicalization simple/relaxed
    KeyTable         ${keyTableFile}
    MustBeSigned     From
    InternalHosts    ${internalHostsFile}
    SignatureTTL     604800
    SigningTable     refile:${signingTableFile}
    SenderHeaders     Sender,From
  '' + (optionalString (cfg.extraConfig != "") cfg.extraConfig);
in
{
  meta.maintainers = [ lib.maintainers.dhess ];

  # Not evaluating for some reason; I'm getting:
  # The option `services.opendkim.keyPath' defined in `/nix/store/.../nixos/modules/rename.nix' does not exist.
  #

  # disabledModules = [ "services/mail/opendkim.nix" ];

  options.services.qx-opendkim = {
    enable = mkEnableOption "an OpenDKIM milter";

    user = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "opendkim";
      description = ''
        The milter will run as this user, and the UNIX domain socket
        that the milter uses to communicate with other processes will
        be owned by this user.
      '';
    };

    group = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "opendkim";
      description = ''
        The milter will run as this group, and the UNIX domain socket
        that the milter uses to communicate with other processes will
        be owned by this group.

        If you want a process to be able to communicate with the
        milter, add the user under which that process runs to this
        group.
      '';
    };

    socket = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "local:/run/opendkim/opendkim.sock";
      readOnly = true;
      description = ''
        The local (UNIX domain) socket on which the milter
        commuicates. The socket is owned by user
        <option>services.opendkim.user</option> and group
        <option>services.opendkim.group</option> and has permissions
        <literal>0660</literal>.

        This option is read-only and is provided for use with other
        modules that need to communicate with the OpenDKIM milter.
      '';
    };

    keyTable = mkOption {
      type = types.attrsOf keyTableRow;
      default = { };
      description = ''
        A declarative OpenDKIM key table. See
        <citerefentry><refentrytitle>opendkim.conf</refentrytitle><manvolnum>5</manvolnum></citerefentry>
        for details.

        Note that any changes to the keys, domains, or selectors in
        this file <strong>must</strong> be accompanied by
        corresponding changes to the DNS TXT records for those
        domains. If the DNS TXT records do not match the contents of
        this file, receiving MXes that check DKIM signatures will
        report failures and may refuse to deliver mail sent with these
        signatures, or mark messages as spam.
      '';
    };

    signingTable = mkOption {
      type = types.listOf signingTableRow;
      default = [ ];
      description = ''
        A declarative OpenDKIM signing table, expressed as a list of
        attributes. See
        <citerefentry><refentrytitle>opendkim.conf</refentrytitle><manvolnum>5</manvolnum></citerefentry>
        for details. '';
    };

    internalHosts = mkOption {
      type = types.listOf pkgs.lib.types.nonEmptyStr;
      default = [ "127.0.0.1" "::1" ];
      description = ''
        A list of hostnames, domain names
        (<literal>.example.com</literal>), IPv4 addresses, or IPv6
        addresses (including CIDR notation addresses). Mail from hosts
        named in this list will be <em>signed</em> by the OpenDKIM
        milter, rather than verified.

        See <citerefentry><refentrytitle>opendkim.conf</refentrytitle><manvolnum>5</manvolnum></citerefentry>
        for details.

        By default, IPv4 and IPv6 localhost IPs are included in this
        list. If you override the default and you want mail from those
        IPs to be signed, you should include them in your overriden
        list.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional user-specified OpenDKIM configuration.";
    };
  };

  config = mkIf cfg.enable {

    # hacknix.assertions.moduleHashes."services/mail/opendkim.nix" =
    #   "0f20f660b11caa365813f287a0dc1ddfc6410a2d9c5184d6787c1764d0ed20aa";

    assertions = [
      {
        assertion = !opendkimEnabled;
        message =
          "Both 'services.opendkim' and 'services.qx-opendkim' cannot be enabled at the same time";
      }
    ];

    users.users = optionalAttrs (cfg.user == "opendkim") {
      opendkim = {
        name = "opendkim";
        group = cfg.group;
        uid = config.ids.uids.opendkim;
        isSystemUser = true;
      };
    };

    users.groups = optionalAttrs (cfg.group == "opendkim") {
      opendkim = {
        name = "opendkim";
        gid = config.ids.gids.opendkim;
      };
    };

    environment.systemPackages = [ pkgs.opendkim ];

    systemd.services.opendkim = rec {
      description = "OpenDKIM signing and verification daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script =
        "${pkgs.opendkim}/bin/opendkim -f -l -x ${configFile} -p ${cfg.socket}";

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        RuntimeDirectory = "opendkim";
        Restart = "always";
        RestartSec = 5;
      };
    };

  };
}
