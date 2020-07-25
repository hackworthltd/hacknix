# # Configuration for what Postfix calls a "null client," i.e., a host
## that can only send mail to another host. This configuration
## enforces an encrypted transport from the client to the relay host.

# Generally speaking, my approach here is to name options by their
# actual Postfix name, so that the mapping between options specified
# here to what goes into the Postfix config file is clear. (With the
# NixOS option names, which are slightly different than the Postfix
# option names, I find that I have to dig through the postfix.nix file
# to figure out exactly what's going to be set to what.)

{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.postfix-null-client;
  enabled = cfg.enable;
  key = config.hacknix.keychain.keys.postfix-null-client-cert;
  user = config.services.postfix.user;
  group = config.services.postfix.group;
in
{
  options.services.postfix-null-client = {

    enable = mkEnableOption ''
      a Postfix null client, i.e., a client that can only send mail.
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

    relayHost = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "mail.example.com";
      description = ''
        The hostname portion of Postfix's <literal>relayhost</literal>
        setting.
      '';
    };

    relayPort = mkOption {
      type = pkgs.lib.types.port;
      default = 587;
      example = 25;
      description = ''
        The port number portion of Postfix's
        <literal>relayhost</literal> setting.
      '';
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
        The null client's private key file, as a string literal. Note
        that this secret will not be copied to the Nix store. However,
        upon start-up, the service will copy a file containing the key
        to its persistent state directory.
      '';
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/postfix-null-client";
      example = "/var/lib/postfix";
      description = ''
        Where the service stores the file containing the client's
        private key file.
      '';
    };

  };

  config = mkIf enabled {

    hacknix.assertions.moduleHashes."services/mail/postfix.nix" =
      "a266b2758334cdcb9308081bd2a3e7cd289c5032ef176c8543b89811b97e0e61";

    hacknix.keychain.keys.postfix-null-client-cert = {
      inherit user group;
      destDir = "${cfg.stateDir}/keys";
      text = cfg.smtpTlsKeyLiteral;
    };

    services.postfix = {
      enable = true;

      domain = cfg.myDomain;
      origin = cfg.myOrigin;

      # See
      # http://www.postfix.org/STANDARD_CONFIGURATION_README.html#null_client
      destination = [ "" ];

      relayHost = cfg.relayHost;
      relayPort = cfg.relayPort;

      sslCert = "${cfg.smtpTlsCertFile}";
      sslKey = key.path;

      config = {
        # Override setting in postfix module when TLS certs are
        # specified.
        smtp_tls_security_level = mkForce "encrypt";
      };

      extraConfig = ''

        ##
        ## postfix-null-client.nix extraConfig begins here.

        biff = no

        # appending .domain is the MUA's job.
        append_dot_mydomain = no

        inet_interfaces = loopback-only
        local_transport = error:local delivery is disabled

        smtp_tls_CAfile = ${cfg.smtpTlsCAFile}
        smtpd_tls_CAfile = ${cfg.smtpTlsCAFile}

        smtp_tls_loglevel = 1
      '';
    };

    systemd.services.postfix = rec {
      wants = [ "postfix-null-client-cert-key.service" ];
      after = wants;
    };

  };

  meta.maintainers = lib.maintainers.dhess;

}
