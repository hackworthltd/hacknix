# # Generally speaking, my approach here is to name options by their
## actual Postfix name, so that the mapping between options specified
## here to what goes into the Postfix config file is clear. (With the
## NixOS option names, which are slightly different than the Postfix
## option names, I find that I have to dig through the postfix.nix file
## to figure out exactly what's going to be set to what.)

{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.postfix-mta;
  enabled = cfg.enable;

  # NOTE - must be the same as upstream.
  stateDir = "/var/lib/postfix/data";
  queueDir = "/var/lib/postfix/queue";
  submission_header_checks =
    pkgs.writeText "submission_header_checks"
      cfg.submission.cleanup.headerChecks;
  smtp_header_checks = pkgs.writeText "smtp_header_checks" cfg.smtpHeaderChecks;
  recipient_access =
    pkgs.writeText "postfix-recipient-access" cfg.smtpd.recipientAccess;
  relay_clientcerts =
    pkgs.writeText "postfix-relay-clientcerts" cfg.relayClientCerts;
  login_maps = pkgs.writeText "login_maps" cfg.submission.smtpd.senderLoginMaps;
  bogus_mx = pkgs.writeText "postfix-bogus-mx" ''
    0.0.0.0/8              REJECT Domain MX in broadcast network (RFC 1700)
    10.0.0.0/8             REJECT No route to your network (RFC 1918)
    127.0.0.0/8            REJECT Domain MX in loopback network (RFC 5735)
    169.254.0.0/16         REJECT Domain MX in link local network (RFC 3927)
    172.16.0.0/12          REJECT No route to your network (RFC 1918)
    192.0.0.0/24           REJECT Domain MX in reserved IANA network (RFC 5735)
    192.0.2.0/24           REJECT Domain MX in TEST-NET-1 network (RFC 5737)
    192.168.0.0/16         REJECT No route to your network (RFC 1918)
    198.18.0.0/15          REJECT Domain MX reserved for network benchmark tests (RFC 2544)
    198.51.100.0/24        REJECT Domain MX in TEST-NET-2 network (RFC 5737)
    203.0.113.0/24         REJECT Domain MX in TEST-NET-3 network (RFC 5737)
    224.0.0.0/4            REJECT Domain MX in class D multicast network (RFC 3171)
    240.0.0.0/4            REJECT Domain MX in class E reserved network (RFC 1700)
  '';
  acmeChallenge = "/var/lib/acme/acme-challenge";
  acmeCertDir = config.security.acme.certs."${cfg.myHostname}".directory;
  acmeCertPublic = "${acmeCertDir}/fullchain.pem";
  acmeCertPrivate = "${acmeCertDir}/key.pem";
  extraDomains =
    builtins.listToAttrs (
      builtins.map
        (
          name: {
            name = "${name}";
            value = null;
          }
        )
        cfg.acmeExtraDomains
    );
  submissionKeyFile = config.hacknix.keychain.keys."sasl-tls-key".path;
in
{
  meta.maintainers = lib.maintainers.dhess;

  options.services.postfix-mta = {

    enable = mkEnableOption ''
      a Postfix mail transfer agent (MTA), i.e., a host that can send
      and receive mail for one or more domains.

      Note that this particular configuration does not use Postfix to
      delivery deliver mail to local accounts. Mail that is received
      by this MTA (for the domains that it serves) is handed off to an
      MDA via Postfix's virtual_transport option. This accommodates
      the decoupling of mail storage and IMAP hosts, which can often
      be locked down very tightly (e.g., only accessible on an
      internal network, or via VPN), from public mail transport hosts,
      which must be connected to the public Internet and communicate
      with untrusted hosts in order to be useful.

      Furthermore, this configuration will only accept mail relay from
      clients that authenticate via client certificates on the
      submission port.

      For this service to work, you must open TCP ports 25 and 587 for
      the SMTP and submission protocols; and 80 and 443 for ACME
      TLS certificate provisioning.
    '';

    myDomain = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "example.com";
      description = ''
        Postfix's <literal>mydomain<literal> setting.
      '';
    };

    myHostname = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "mx.example.com";
      description = ''
        Postfix's <literal>myhostname</literal> setting.

        Note that this setting is critical to reliable Internet mail
        delivery. It should be the same as the name specified in your
        domains' published TXT records for SPF, assuming you use
        <literal>a:</literal> notation in your TXT SPF records.
      '';
    };

    acmeExtraDomains = mkOption {
      type = pkgs.lib.types.listOf pkgs.lib.types.nonEmptyStr;
      example = "submission.example.com";
      default = [ ];
      description = ''
        A list of domain names that this MTA also answers to (e.g.,
        CNAMEs) for the purposes of acquiring ACME TLS certificates.

        These names will not be used in the Postfix configuration;
        they're merely here to give you a chance to ask the ACME
        server for additional Common Names in the certificates that it
        issues to the MTA host.
      '';
    };

    proxyInterfaces = mkOption {
      type = types.listOf pkgs.lib.types.nonEmptyStr;
      default = [ ];
      example = [ "192.0.2.1" ];
      description = ''
        Postfix's <literal>proxy_interfaces</literal> setting.
      '';
    };

    milters = {
      smtpd = mkOption {
        type = types.listOf pkgs.lib.types.nonEmptyStr;
        default = [ ];
        description = ''
          A list of smtpd milter sockets to use with the MTA.
        '';
      };

      nonSmtpd = mkOption {
        type = types.listOf pkgs.lib.types.nonEmptyStr;
        default = [ ];
        description = ''
          A list of non-smtpd milter sockets to use with the MTA.
        '';
      };
    };

    postscreen = {
      enable = mkEnableOption "postscreen.";

      accessList = mkOption {
        type = types.path;
        description = ''
          This module sets Postfix's
          <literal>postscreen_access_list</literal> to
          <literal>"permit_mynetworks"</literal> and the contents of
          this file, specified in Postfix CIDR table format.
        '';
      };

      blacklistAction = mkOption {
        type = types.enum [ "ignore" "enforce" "drop" ];
        default = "ignore";
        example = "enforce";
        description = ''
          Postfix's <literal>postscreen_blacklist_action</literal> setting.

          The default value ("ignore") is the same as Postfix's default.
        '';
      };

      greetWait = mkOption {
        type = types.nullOr pkgs.lib.types.nonEmptyStr;
        default = null;
        example = "8s";
        description = ''
          Postfix's <literal>postscreen_greet_wait</literal> setting.

          The default is to use Postfix's default value.
        '';
      };

      greetAction = mkOption {
        type = types.enum [ "ignore" "enforce" "drop" ];
        default = "ignore";
        example = "enforce";
        description = ''
          Postfix's <literal>postscreen_greet_action</literal> setting.

          The default value ("ignore") is the same as Postfix's default.
        '';
      };

      dnsblSites = mkOption {
        type = types.listOf pkgs.lib.types.nonEmptyStr;
        default = [ "zen.spamhaus.org" ];
        example = [ "zen.spamhaus.org" "dnsrbl.org" ];
        description = ''
          Postfix's <literal>postscreen_dnsbl_sites</literal> setting.

          The default is to <literal>zen.spamhaus.org</literal> and
          <literal>dnsrbl.org</literal>
        '';
      };

      dnsblAction = mkOption {
        type = types.enum [ "ignore" "enforce" "drop" ];
        default = "ignore";
        example = "enforce";
        description = ''
          Postfix's <literal>postscreen_dnsbl_action</literal> setting.

          The default value ("ignore") is the same as Postfix's default.
        '';
      };
    };

    recipientDelimiter = mkOption {
      type = types.str;
      default = "+";
      example = "+-";
      description = ''
        Postfix's <literal>recipient_delimiter</literal> setting.
      '';
    };

    relayClientCerts = mkOption {
      type = types.lines;
      default = "";
      example = literalExample ''
        D7:04:2F:A7:0B:8C:A5:21:FA:31:77:E1:41:8A:EE:80 lutzpc.at.home
      '';
      description = ''
        A series of client certificate SHA1 fingerprints, one per
        line, as used by by Postfix's
        <literal>relay_clientcerts</literal> setting.

        These fingerprints are consulted wherever the Postfix
        configuration uses the
        <literal>permit_tls_clientcerts</literal> feature. In the
        default <literal>postfix-mta</literal> service configuration,
        this is used by the <option>smtpd.clientRestrictions</option>
        option.

        If you don't use client certificates, just leave this option
        as the default value.
      '';
    };

    smtpd = {
      clientRestrictions = mkOption {
        type = types.nullOr (types.listOf pkgs.lib.types.nonEmptyStr);
        default = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "permit_tls_clientcerts"
          "reject_unknown_reverse_client_hostname"
        ];
        example = literalExample [
          "permit_mynetworks"
          "reject_unknown_client_hostname"
        ];
        description = ''
          Postfix's <literal>smtpd_client_restrictions</literal> setting.

          If null, Postfix's default value will be used.
        '';
      };

      # NOTE: we should include reject_unknown_helo_hostname, but it
      # appears to be a common problem with Exchange servers (gee,
      # what a surprise), and also Apple mail servers (!), that they
      # send e-mail with the HELO set to some internal domain name
      # that doesn't resolve on the public Internet, so this is
      # probably too strict to get away with, despite the fact that
      # it's a violation of RFC 2821 section 3.6.

      heloRestrictions = mkOption {
        type = types.nullOr (types.listOf pkgs.lib.types.nonEmptyStr);
        # XXXX TODO dhess - add helo_checks for our own MXes.
        default = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "permit_tls_clientcerts"
          "reject_invalid_helo_hostname"
          "reject_non_fqdn_helo_hostname"
        ];
        example =
          literalExample [ "permit_mynetworks" "reject_invalid_helo_hostname" ];
        description = ''
          Postfix's <literal>smtpd_helo_restrictions</literal> setting.

          If null, Postfix's default value will be used.
        '';
      };

      senderRestrictions = mkOption {
        type = types.nullOr (types.listOf pkgs.lib.types.nonEmptyStr);
        default = [
          "reject_non_fqdn_sender"
          "reject_unknown_sender_domain"
          "check_sender_mx_access hash:/etc/postfix/bogus_mx"
        ];
        example =
          literalExample [ "permit_mynetworks" "reject_invalid_helo_hostname" ];
        description = ''
          Postfix's <literal>smtpd_sender_restrictions</literal> setting.

          If null, Postfix's default value will be used.
        '';
      };

      relayRestrictions = mkOption {
        type = types.nullOr (types.listOf pkgs.lib.types.nonEmptyStr);
        default = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "permit_tls_clientcerts"
          "reject_non_fqdn_recipient"
          "reject_unauth_destination"
        ];
        example = literalExample [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "defer_unauth_destination"
        ];
        description = ''
          Postfix's <literal>smtpd_relay_restrictions</literal> setting.

          If null, Postfix's default value will be used.

          Note that either this option or
          <option>recipientRestrictions</option> must specify certain
          restrictions, or else Postfix will refuse to deliver mail.
          See the Postfix documentation for details. (The default
          values of these options satisfy the requirements.)
        '';
      };

      recipientAccess = mkOption {
        type = types.lines;
        default = "";
        example = ''
          nospam@example.org REJECT go away
        '';
        description = ''
          Entries in Postfix's smtpd recipient access table. See the
          Postfix <literal>access(5)</literal> man page for details.
        '';
      };

      recipientRestrictions = mkOption {
        type = types.nullOr (types.listOf pkgs.lib.types.nonEmptyStr);

        # XXX TODO dhess - add check_recipient_access with roleaccount_exceptions.
        default = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "permit_tls_clientcerts"
          "reject_unknown_recipient_domain"
          "reject_unverified_recipient"
          "check_recipient_access hash:/etc/postfix/recipient_access"
        ];
        example = literalExample [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "defer_unauth_destination"
        ];
        description = ''
          Postfix's <literal>smtpd_recipient_restrictions</literal> setting.

          If null, Postfix's default value will be used.

          Note that many Postfix guides recommend using RBL/DNSBL
          checks here; by default, we do not, because we assume that a
          milter such as rspamd will be used, and those generally do a
          better/more comprehensive job.

          Note also that either this option or
          <option>relayRestrictions</option> must specify certain
          restrictions, or else Postfix will refuse to deliver mail.
          See the Postfix documentation for details. (The default
          values of these options satisfy the requirements.)
        '';
      };

      dataRestrictions = mkOption {
        type = types.nullOr (types.listOf pkgs.lib.types.nonEmptyStr);
        default = [ "reject_unauth_pipelining" ];
        example = literalExample [ "reject_multi_recipient_bounce" ];
        description = ''
          Postfix's <literal>smtpd_data_restrictions</literal> setting.

          If null, Postfix's default value will be used.
        '';
      };
    };

    smtpHeaderChecks = mkOption {
      type = pkgs.lib.types.nullOr pkgs.lib.types.lines;
      default = null;
      description = ''
        If non-null, this option specifies PCRE-formatted lines of
        Postfix <literal>smtp_header_checks</literal>.

        See Postfix's <literal>smtp_header_checks(5)</literal> man
        page for details on the format of the checks.
      '';
    };

    submission = {
      listenAddresses = mkOption {
        type =
          types.listOf (types.either pkgs.lib.types.ipv4NoCIDR pkgs.lib.types.ipv6NoCIDR);
        default = [ ];
        example = [ "127.0.0.1" "::1" "10.0.0.2" "2001:db8::2" ];
        description = ''
          A list of IPv4 and/or IPv6 addresses on which Postfix will
          listen for incoming submission connections.

          Note that you should also list any loopback addresses here on
          which you want Postfix to accept local submission requests.

          If empty (the default), Postfix will listen on all active
          interfaces for incoming submission connections.
        '';
      };

      myHostname = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = cfg.myHostname;
        example = "submission.example.com";
        description = ''
          Postfix's <literal>myhostname</literal> setting for the
          submission server.

          By default, this value is the same as
          <option>myHostname</option>, but it's sometimes useful to
          use different names for submission and SMTP.
        '';
      };

      # Generally speaking, we're less picky about client restrictions
      # on submission clients as we assume they're authenticated (via
      # SASL, TLS cert, etc.), so we have separate settings for the
      # submission service.

      smtpd = {

        clientRestrictions = mkOption {
          type = types.listOf pkgs.lib.types.nonEmptyStr;
          default = [ "permit_sasl_authenticated" "reject" ];
          example = literalExample [
            "permit_sasl_authenticated"
            "permit_tls_clientcerts"
            "reject"
          ];
          description = ''
            The submission server's
            <literal>smtpd_client_restrictions</literal> setting.
          '';
        };

        saslPath = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          default = "private/auth";
          example = "inet:dovecot.example.com:12345";
          description = ''
            Postfix's <literal>smtpd_sasl_path</literal> setting
            for the submission server.

            The default value points to a local Dovecot server's
            SASL UNIX domain socket.
          '';
        };

        saslType = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          default = "dovecot";
          example = "cyrus";
          description = ''
            Postfix's <literal>smtpd_sasl_type</literal> setting
            for the submission server.

            The default value configures Postfix to use Dovecot
            SASL.
          '';
        };

        senderLoginMaps = mkOption {
          type = types.lines;
          default = builtins.readFile ./login_map;
          description = ''
            PCRE-style entries for Postfix's
            <literal>smtpd_sender_login_maps</literal> file. Entries
            in this map will be used to determine which aliases
            authenticated submission clients can use for their MAIL
            FROM address.

            The default file limits users to sending MAIL FROM only
            the email address they used to authenticate with the
            submission server. This is often not what you want, so you
            should read the following helpful links carefully to
            determine how to configure this for your own MTA servers:

            https://serverfault.com/questions/318334/how-to-enforce-sender-address-to-be-logged-in-userexample-org-in-postfix
            https://wiki2.dovecot.org/HowTo/PostfixAndDovecotSASL#Using_SASL_with_Postfix_submission_port
            https://blog.felipe-alfaro.com/2006/02/19/block-sender-address-spoofing-with-smpt-auth/
          '';
        };

        tlsCertFile = mkOption {
          type = types.path;
          description = ''
            Postfix's <literal>smtpd_tls_cert_file</literal> setting
            for the submission server.

            Note that this certificate is only used for the submission
            server, not for communication with public SMTP servers.
            This is because, typically, you want to use a self-signed
            CA and certificate for TLS encryption with your submission
            clients.

            If you do use your own self-signed CA and certificate,
            this certificate file should include the full chain:
            root CA all the way down to the server certificate
            itself.
          '';
        };

        tlsKeyLiteral = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "<private key>";
          description = ''
            The private key corresponding to the
            <option>submission.smtpdTLSCertFile</option> option,
            represented as a string literal.

            This key will be written to a file that is securely
            deployed to the host. It will not be written to the Nix
            store.
          '';
        };
      };

      cleanup = {
        headerChecks = mkOption {
          type = pkgs.lib.types.nullOr pkgs.lib.types.lines;
          default = null;
          description = ''
            If non-null, this option specifies a Postfix
            <literal>header_checks</literal> PCRE-formatted file that
            is only applied to mail that's processed by the submission
            service. These header checks are not applied to mail sent
            via Postfix's standard SMTP service. The separate header
            checks are implemented via a custom Postfix
            <literal>cleanup</literal> daemon for the submission
            service.

            If null (the default), no special header checks are
            performed for the submission service, and whatever
            <literal>postfix.headerChecks</literal> options you
            specify are applied to mail processed by both the SMTP and
            submission services.

            See Postfix's <literal>header_checks(5)</literal> man page
            for details on the format of the checks.
          '';
        };
      };
    };

    virtual = {
      transport = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "lmtp:hostname:port";
        description = ''
          Postfix's <literal>virtual_transport</literal> setting.
        '';
      };

      mailboxDomains = mkOption {
        type = types.nonEmptyListOf pkgs.lib.types.nonEmptyStr;
        default = [ "$mydomain" ];
        example = literalExample [ "$mydomain" "another.local.tld" ];
        description = ''
          Postfix's <literal>virtual_mailbox_domains</literal> setting.
        '';
      };

      aliasDomains = mkOption {
        type = types.listOf pkgs.lib.types.nonEmptyStr;
        default = [ ];
        example = literalExample [ "another.local.tld" ];
        description = ''
          Postfix's <literal>virtual_alias_domains</literal> setting.
        '';
      };

      aliasMaps = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Entries for the Postfix's <literal>virtual_alias_maps</literal> file.
        '';
      };
    };

    transport = mkOption {
      type = types.lines;
      default = "";
      description =
        "\n        Entries for Postfix's <literal>transport_map</literal> file.\n      ";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra Postfix configuration.
      '';
    };
  };

  config = mkIf enabled {

    hacknix.assertions.moduleHashes."services/mail/postfix.nix" =
      "41def83d30cb0e331fae7e7433cb0a89ac0f5e0b39feb7bb05f2f34087c59d93";
    hacknix.assertions.moduleHashes."security/acme.nix" =
      "d1c04ff1a5aa0388d12b8286d7500442fff8e0acbcb89321f6fa0ac93f52837e";

    hacknix.keychain.keys."sasl-tls-key" = {
      destDir = "/var/lib/postfix/keys";
      text = cfg.submission.smtpd.tlsKeyLiteral;
      user = config.services.postfix.user;
      group = config.services.postfix.group;
      permissions = "0400";
    };

    hacknix.defaults.acme.enable = true;

    # This Nginx vhost exists only to provision ACME certs for the
    # Postfix MTA.

    services.nginx = {
      enable = true;
      virtualHosts."${cfg.myHostname}" = {
        forceSSL = true;
        useACMEHost = "${cfg.myHostname}";
        locations."/" = { root = acmeChallenge; };
      };
    };

    # We need a group that both nginx and postfix belong to, so that
    # the ACME service can set the correct permissions on the ACME
    # certificate keys. nginx needs to be able to serve them as proof
    # of ownership to ACME, and postfix needs to be able to read them
    # to present them to clients.

    users.groups.postfix-acme = {
      members = [ config.services.postfix.user config.services.nginx.user ];
    };

    # If this MX is configured correctly, we only need the ACME cert
    # for myhostname, as that's the name that it'll be reporting both
    # to SMTP clients (upon mail receipt) and to SMTP servers (upon
    # mail delivery). In other words, we don't need to add any virtual
    # domains to the ACME extraDomains.

    security.acme.certs."${cfg.myHostname}" = {
      inherit extraDomains;
      webroot = acmeChallenge;
      email = "postmaster@${cfg.myDomain}";
      allowKeysForGroup = true;
      group = config.users.groups.postfix-acme.name;
      postRun = ''
        systemctl reload postfix
        systemctl reload nginx
      '';
    };

    services.postfix = {
      enable = true;
      domain = cfg.myDomain;
      origin = "$mydomain";
      hostname = cfg.myHostname;

      recipientDelimiter = cfg.recipientDelimiter;

      # Disable Postfix delivery; all delivery goes through the
      # virtual transport.

      destination = [ "" ];

      virtual = cfg.virtual.aliasMaps;
      transport = cfg.transport;

      sslCert = acmeCertPublic;
      sslKey = acmeCertPrivate;

      mapFiles = {
        "recipient_access" = recipient_access;
        "relay_clientcerts" = relay_clientcerts;
        "bogus_mx" = bogus_mx;
      };

      config = {
        milter_default_action = "accept";
        smtpd_milters = cfg.milters.smtpd;
        non_smtpd_milters = cfg.milters.nonSmtpd;

        biff = "no";

        proxy_interfaces = cfg.proxyInterfaces;

        append_dot_mydomain = "no";
        remote_header_rewrite_domain = "domain.invalid";

        mynetworks_style = "host";
        relay_domains = "";

        virtual_transport = cfg.virtual.transport;
        virtual_mailbox_domains = cfg.virtual.mailboxDomains;
        virtual_alias_domains = cfg.virtual.aliasDomains;

        relay_clientcerts = "hash:/etc/postfix/relay_clientcerts";

        smtpd_tls_fingerprint_digest = "sha1";
        smtpd_tls_security_level = "may";
        smtpd_tls_auth_only = "yes";
        smtpd_tls_loglevel = "1";
        smtpd_tls_received_header = "yes";
        smtpd_tls_dh1024_param_file = "${pkgs.ffdhe2048Pem}";

        # We're pretty draconian about what we accept and what we ask
        # for. If this causes problems with old versions of qmail and
        # Microsoft Exchange Server 2003, well, so be it. It's 2019;
        # get a better mail server.
        smtpd_tls_ask_ccert = "yes";
        tls_preempt_cipherlist = "yes";

        smtp_tls_security_level = "may";
        smtp_tls_loglevel = "1";
        smtp_tls_note_starttls_offer = "yes";

        unverified_recipient_reject_reason = "Address lookup failed";
      } // (
        if cfg.postscreen.enable then {
          postscreen_access_list =
            [ "permit_mynetworks" "cidr:${cfg.postscreen.accessList}" ];
          postscreen_blacklist_action = cfg.postscreen.blacklistAction;
          postscreen_greet_wait = cfg.postscreen.greetWait;
          postscreen_greet_action = cfg.postscreen.greetAction;
          postscreen_dnsbl_sites = cfg.postscreen.dnsblSites;
          postscreen_dnsbl_action = cfg.postscreen.dnsblAction;
        } else
          { }
      ) // (
        if cfg.smtpHeaderChecks != null then {
          smtp_header_checks = "pcre:${smtp_header_checks}";
        } else
          { }
      );

      extraConfig =
        let
          smtpd_client_restrictions =
            optionalString
              (cfg.smtpd.clientRestrictions != null)
              (
                "smtpd_client_restrictions = "
                + (concatStringsSep ", " cfg.smtpd.clientRestrictions)
              );
          smtpd_helo_restrictions =
            optionalString
              (cfg.smtpd.heloRestrictions != null)
              (
                "smtpd_helo_restrictions = "
                + (concatStringsSep ", " cfg.smtpd.heloRestrictions)
                + (
                  optionalString (cfg.smtpd.heloRestrictions != [ ]) ''

              smtpd_helo_required = yes''
                )
              );
          smtpd_sender_restrictions =
            optionalString
              (cfg.smtpd.senderRestrictions != null)
              (
                "smtpd_sender_restrictions = "
                + (concatStringsSep ", " cfg.smtpd.senderRestrictions)
              );
          smtpd_relay_restrictions =
            optionalString
              (cfg.smtpd.relayRestrictions != null)
              (
                "smtpd_relay_restrictions = "
                + (concatStringsSep ", " cfg.smtpd.relayRestrictions)
              );
          smtpd_recipient_restrictions =
            optionalString
              (cfg.smtpd.recipientRestrictions != null)
              (
                "smtpd_recipient_restrictions = "
                + (concatStringsSep ", " cfg.smtpd.recipientRestrictions)
              );
          smtpd_data_restrictions =
            optionalString
              (cfg.smtpd.dataRestrictions != null)
              (
                "smtpd_data_restrictions = "
                + (concatStringsSep ", " cfg.smtpd.dataRestrictions)
              );
          submission_cleanup_service =
            optionalString (cfg.submission.cleanup.headerChecks != null) ''
              submission_cleanup_service_name = submission_cleanup
              submission_header_checks = pcre:${submission_header_checks}
            '';
        in
        ''
          ${smtpd_client_restrictions}
          ${smtpd_helo_restrictions}
          ${smtpd_sender_restrictions}
          ${smtpd_relay_restrictions}
          ${smtpd_recipient_restrictions}
          ${smtpd_data_restrictions}
          ${submission_cleanup_service}
        '' + cfg.extraConfig;

      # We don't use enableSubmission here because we may want to
      # limit it to just the listenAddresses, and the NixOS
      # submissionOptions is too limited to permit that. We have to
      # construct the "submission" master.cf line manually.
      #
      # We also don't use enableSmtp because we want to disable MIME
      # output conversion, to avoid breaking DKIM signatures, and
      # upstream doesn't support this.
      #
      # Finally, we use postscreen, so we need to tweak the upstream
      # smtp_inet definition.
      #
      # Note: smtpd_client_restrictions here will allow submission
      # clients that present a TLS client certificate to relay mail
      # *for this MTA's domains only*, because the Postfix
      # configuration only permits mail to be sent to other domains by
      # authenticated clients, and presenting a TLS client certificate
      # does not count as "authenticated." (It might make sense to
      # change this if, for example, more clients started supporting
      # TLS client certificates.)

      enableSubmission = false;
      enableSmtp = false;
      masterConfig =
        let
          smtpd_client_restrictions =
            concatStringsSep "," cfg.submission.smtpd.clientRestrictions;
          submission_cleanup_args =
            if cfg.submission.cleanup.headerChecks != null then [
              "-o"
              "cleanup_service_name=$submission_cleanup_service_name"
            ] else
              [ ];
          value = {
            type = "inet";
            private = false;
            command = "smtpd";
            args = [
              "-o"
              "myhostname=${cfg.submission.myHostname}"
              "-o"
              "tls_preempt_cipherlist=yes"
              "-o"
              "syslog_name=postfix/submission"
              "-o"
              "smtpd_tls_security_level=encrypt"
              "-o"
              "smtpd_tls_mandatory_ciphers=high"
              "-o"
              "smtpd_tls_mandatory_protocols=!SSLv2,!SSLv3,!TLSv1,!TLSv1.1"
              "-o"
              "smtpd_tls_cert_file=${cfg.submission.smtpd.tlsCertFile}"
              "-o"
              "smtpd_tls_key_file=${submissionKeyFile}"
              "-o"
              "smtpd_tls_ask_ccert=yes"
              "-o"
              "smtpd_sasl_auth_enable=yes"
              "-o"
              "smtpd_sasl_path=${cfg.submission.smtpd.saslPath}"
              "-o"
              "smtpd_sasl_type=${cfg.submission.smtpd.saslType}"
              "-o"
              "smtpd_sasl_security_options=noanonymous,noplaintext"
              "-o"
              "smtpd_sasl_tls_security_options=noanonymous"
              "-o"
              "smtpd_sasl_local_domain=$mydomain"
              "-o"
              "smtpd_sasl_authenticated_header=yes"
              "-o"
              "smtpd_client_restrictions=${smtpd_client_restrictions}"
              "-o"
              "milter_macro_daemon_name=ORIGINATING"
              "-o"
              "smtpd_sender_restrictions=reject_sender_login_mismatch"
              "-o"
              "smtpd_sender_login_maps=pcre:${login_maps}"
            ] ++ submission_cleanup_args;
          };
        in
        (
          if cfg.submission.listenAddresses != [ ] then
            (
              listToAttrs (
                map
                  (
                    ip: {
                      name = "[${ip}]:submission";
                      inherit value;
                    }
                  )
                  cfg.submission.listenAddresses
              )
            )
          else {
            submission = value;
          }
        ) // {
          smtp = { args = [ "-o" "disable_mime_output_conversion=yes" ]; };
          relay = {
            command = "smtp";
            args = [
              "-o"
              "smtp_fallback_relay="
              "-o"
              "disable_mime_output_conversion=yes"
            ];
          };
        } // (
          if cfg.postscreen.enable then {
            smtp_inet = mkForce {
              name = "smtp";
              type = "inet";
              private = false;
              maxproc = 1;
              command = "postscreen";
            };
            smtpd_pass = {
              name = "smtpd";
              type = "pass";
              command = "smtpd";
            };
            tlsproxy = {
              name = "tlsproxy";
              type = "unix";
              command = "tlsproxy";
              maxproc = 0;
            };
            dnsblog = {
              name = "dnsblog";
              type = "unix";
              command = "dnsblog";
              maxproc = 0;
            };
          } else
            { }
        ) // (
          if cfg.submission.cleanup.headerChecks != null then {
            submission_cleanup = {
              private = false;
              maxproc = 0;
              command = "cleanup";
              args = [
                "-o"
                "header_checks=$submission_header_checks"
                "-o"
                "syslog_name=postfix/submission"
              ];
            };
          } else
            { }
        );
    };
  };

}
