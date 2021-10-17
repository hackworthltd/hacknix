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

    smtpTlsKeyFile = mkOption {
      type = pkgs.lib.types.nonStorePath;
      example = "/var/lib/keys/tls.key";
      description = ''
        A path to a file containing the null client's private key.

        This key should be owned by the Postfix user and group.
      '';
    };
  };

  config = mkIf enabled {

    hacknix.assertions.moduleHashes."services/mail/postfix.nix" =
      "d77d8791f2498738b5d97653a9bfcfb2f69f48d1546868ab1be0c4273bfac6c4";

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
      sslKey = cfg.smtpTlsKeyFile;

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
  };

  meta.maintainers = lib.maintainers.dhess;
}
