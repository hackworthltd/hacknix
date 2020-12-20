# # Configuration for an opinionated Postfix relay host, i.e., a host
## that can send mail *to a prescribed set of domains* on behalf of
## other hosts. One typical use for such a service is to support
## oddball hardware (e.g., a UPS) that can send email, but not
## securely; or to limit outbound SMTP access to a limited number of
## hosts that run the relay service.

# Generally speaking, my approach here is to name options by their
# actual Postfix name, so that the mapping between options specified
# here to what goes into the Postfix config file is clear. (With the
# NixOS option names, which are slightly different than the Postfix
# option names, I find that I have to dig through the postfix.nix file
# to figure out exactly what's going to be set to what.)

{ config, pkgs, lib, ... }:

with lib;
let
  globalCfg = config;
  cfg = config.services.postfix-relay-host;
  enabled = cfg.enable;
  key = config.hacknix.keychain.keys.postfix-relay-host-cert;

  # NOTE - must be the same as upstream.
  stateDir = "/var/lib/postfix/data";
  user = config.services.postfix.user;
  group = config.services.postfix.group;
  dhParamsFile = "${stateDir}/dh.pem";
in
{
  options.services.postfix-relay-host = {

    enable = mkEnableOption ''
      a Postfix relay host, i.e., a host that can send email to a
      <em>prescribed set of domains</em> on behalf of other hosts.

      <strong>Do not</strong> run this service on an untrusted
      network, e.g., on the public Internet. It configures Postfix to
      accept mail from any host as long as the recipient address is in
      the prescribed set of relay domains. The consequences of a rogue
      mail agent using this service are less severe than they would be
      on a full mailhost, since only recipients in the set of relay
      domains could be spammed by such an agent; but it would still be
      detrimental to recipients in the relay domains.

      This configuration enforces a high-security encrypted transport
      from this host to the remote relay host. This requires trusted
      TLS certificates and the requisite TLS configuration on the
      remote relay host.

      On the other hand, clients of this relay host are given a bit
      more leeway, given that many SMTP-enabled devices have poor SMTP
      client implementations for which secure configurations may not
      be practical, or even possible. Therefore, the preferred way to
      connect to this relay host service is via port 587 with client
      certificate authorization (using a pre-computed fingerprint),
      but clients that are not capable of this are allowed to connect
      with a plaintext connection over port 25.
    '';

    myDomain = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "example.com";
      description = ''
        Postfix's <literal>mydomain<literal> setting.
      '';
    };

    myOrigin = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "example.com";
      description = ''
        Postfix's <literal>myorigin</literal> setting. On Debian
        systems, this comes from <literal>/etc/mailname</literal>.
      '';
    };

    masqueradeDomains = mkOption {
      type = types.nullOr (types.nonEmptyListOf pkgs.lib.types.nonEmptyStr);
      default = null;
      example = [ "foo.example.com" "example.com" ];
      description = ''
        Strip leading subdomain structure from outgoing email
        addresses. In the example given,
        <literal>bob@vader.foo.example.com</literal> becomes
        <literal>bob@foo.example.com</literal>, and
        <literal>alice@bar.example.com</literal> becomes
        <literal>alice@example.com</literal>.

        This is useful with broken mailers that insist on using their
        FQDN (e.g., OpenBSD).
      '';
    };

    relayDomains = mkOption {
      type = types.listOf pkgs.lib.types.nonEmptyStr;
      default = [ ];
      example = [ "example.com" "example.net" ];
      description = ''
        A list of domains for which this Postfix service will accept
        RCPT TO requests, i.e., for which it will accept and relay
        mail.

        If you want to accept mail for a domain's subdomains as well
        (e.g., for <literal>example.com</literal> as well as
        <literal>*.example.com</literal>), it's best to specify both
        <literal>example.com</literal> and
        <literal>.example.com</literal>, for future-proofing. (In the
        future, Postfix will require the latter convention.)
      '';
    };

    relayHost = mkOption {
      type = types.str;
      default = "";
      description = "\n        Mail relay for outbound mail.\n      ";
    };

    relayPort = mkOption {
      type = types.int;
      default = 25;
      description = "\n        SMTP port for relay mail relay.\n      ";
    };

    relayClientCertFingerprintsFile = mkOption {
      type = types.path;
      description = ''
        A file containing the authorized client certificate SHA1
        fingerprints, one per line, as generated by the command:

        <literal>openssl x509 -in client-cert.pem -noout -fingerprint</literal>

        Clients whose certificates are listed in this file will be
        permitted to connect securely; others will have to connect
        via plaintext.
      '';
    };

    lookupMX = mkOption {
      type = types.bool;
      default = false;
      description =
        "\n        Whether relay specified is just domain whose MX must be used.\n      ";
    };

    smtpTlsCAFile = mkOption {
      type = types.path;
      description = ''
        A path to the CA certificate to be used to authenticate SMTP
        connections.
      '';
    };

    smtpTlsCertFile = mkOption {
      type = types.path;
      description = ''
        A path to the client certificate to be used to authenticate
        SMTP client connections.
      '';
    };

    smtpTlsKeyLiteral = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "<key>";
      description = ''
        The relay host's private key file, as a string literal. Note
        that this secret will not be copied to the Nix store. However,
        upon start-up, the service will copy a file containing the key
        to its persistent state directory.
      '';
    };

    listenAddresses = mkOption {
      type =
        types.nonEmptyListOf (types.either pkgs.lib.types.ipv4NoCIDR pkgs.lib.types.ipv6NoCIDR);
      default = [ "127.0.0.1" "::1" ];
      example = [ "127.0.0.1" "::1" "10.0.0.25" "2001:db8::25" ];
      description = ''
        A list of IPv4 and/or IPv6 addresses on which Postfix will
        listen for incoming connections.

        Note that you should also list any loopback addresses here on
        which you want Postfix to accept local delivery to the relay
        domains.
      '';
    };

  };

  config = mkIf enabled {

    hacknix.assertions.moduleHashes."services/mail/postfix.nix" =
      "2dd7600f164b768532e671e32310e7b851f1fa2034c477e29f685317ae82a4c0";

    hacknix.keychain.keys.postfix-relay-host-cert = {
      inherit user group;
      destDir = "${stateDir}/keys";
      text = cfg.smtpTlsKeyLiteral;
    };

    assertions = [
      {
        assertion = !globalCfg.services.postfix-null-client.enable;
        message =
          "Only one of `services.postfix-null-client` and `services.postfix-relay-host` can be set";
      }
    ];

    services.postfix = {
      enable = true;

      # We don't use enableSubmission here because we want to limit it
      # to just the listenAddresses, and the NixOS submissionOptions is
      # too limited to permit that. We have to construct the
      # "submission" master.cf line manually.

      enableSubmission = false;
      masterConfig =
        listToAttrs
          (
            map
              (
                ip: {
                  name = "[${ip}]:submission";
                  value = {
                    type = "inet";
                    private = false;
                    command = "smtpd";
                    args = [
                      "-o"
                      "milter_macro_daemon_name=ORIGINATING"
                      "-o"
                      "smtpd_client_restrictions=permit_tls_clientcerts,reject"
                      "-o"
                      "smtpd_reject_unlisted_recipient=no"
                      "-o"
                      "smtpd_tls_dh1024_param_file=${dhParamsFile}"
                      "-o"
                      "smtpd_tls_security_level=encrypt"
                      "-o"
                      "syslog_name=postfix/submission"
                      "-o"
                      "tls_preempt_cipherlist=yes"
                    ];
                  };
                }
              )
              cfg.listenAddresses
          )

        //
        listToAttrs (
          map
            (
              ip: {
                name = "[${ip}]:smtp";
                value = {
                  type = "inet";
                  private = false;
                  command = "smtpd";
                };
              }
            )
            cfg.listenAddresses
        )

        // {
          # Nixpkgs postfix module always enables smtp inet; we have to
          # override it here.
          #
          # Note: this is a bit of a hack. It works because the name of
          # the service is at the beginning of the line and we can
          # change its name to be a comment.
          smtp_inet = { name = mkForce "#smtp"; };
        };

      domain = cfg.myDomain;
      origin = cfg.myOrigin;

      # Disable local delivery.
      destination = [ "" ];

      relayDomains = cfg.relayDomains;

      relayHost = cfg.relayHost;
      relayPort = cfg.relayPort;
      lookupMX = cfg.lookupMX;

      sslCert = "${cfg.smtpTlsCertFile}";
      sslKey = key.path;

      mapFiles = { relay_clientcerts = cfg.relayClientCertFingerprintsFile; };

      config = {
        # Override setting in postfix module when TLS certs are
        # specified.
        smtp_tls_security_level = mkForce "encrypt";
      };

      extraConfig = ''

        ##
        ## postfix-relay-host.nix extraConfig begins here.

        biff = no

        # appending .domain is the MUA's job.
        append_dot_mydomain = no

        local_transport = error:local delivery is disabled

        ${optionalString (cfg.masqueradeDomains != null) ''
          masquerade_domains = ${concatStringsSep " " cfg.masqueradeDomains}
          masquerade_classes = envelope_sender, envelope_recipient, header_sender, header_recipient
        ''}

        smtp_tls_CAfile = ${cfg.smtpTlsCAFile}
        smtpd_tls_CAfile = {cfg.smtpTlsCAFile}

        smtpd_tls_security_level = may
        smtpd_tls_session_cache_database = btree:${stateDir}/smtpd_scache
        smtpd_tls_loglevel = 1
        smtpd_tls_auth_only = yes
        smtpd_tls_ask_ccert = yes
        smtpd_tls_fingerprint_digest = sha1
        smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
        smtpd_tls_dh1024_param_file = ${dhParamsFile}
        smtpd_tls_eecdh_grade = strong
        smtpd_tls_received_header = yes
        smtpd_relay_restrictions = permit_auth_destination reject

        smtp_tls_session_cache_database = btree:${stateDir}/smtp_scache
        smtp_tls_loglevel = 1
        smtp_tls_mandatory_protocols = !SSLv2, !SSLv3
        smtp_tls_mandatory_ciphers = high

        relay_clientcerts = hash:/var/lib/postfix/conf/relay_clientcerts
      '';
    };

    systemd.services.postfix = rec {
      wants = [ "postfix-relay-host-cert-key.service" ];
      after = wants;
    };

  };

  meta.maintainers = lib.maintainers.dhess;

}
