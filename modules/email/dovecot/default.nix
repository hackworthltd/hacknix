{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.dovecot2;
  dovecotPkg = pkgs.dovecot;
  baseDir = "/run/dovecot2";
  stateDir = "/var/lib/dovecot";
  antiSpamSieveScripts = {
    imapsieve_mailbox1_before = ./report-spam.sieve;
    imapsieve_mailbox2_before = ./report-ham.sieve;
  };
  dovecotConf =
    let
      imapPlugins = optionalString (cfg.antispam.enable) "imap_sieve";
    in
    concatStrings [
      ''
        base_dir = ${baseDir}
        protocols = ${concatStringsSep " " cfg.protocols}
        sendmail_path = /run/wrappers/bin/sendmail

        ssl_cert = <${cfg.sslServerCert}
        ssl_key = <${cfg.sslServerKey}
        ssl_ca = <${cfg.sslCACert}
        ssl_dh = <${cfg.dhParamsFile}
        ssl_prefer_server_ciphers = yes
        ssl_min_protocol = TLSv1.2
        ssl_cipher_list = ${cfg.sslCiphers}

        disable_plaintext_auth = yes

        default_internal_user = ${cfg.user}
        default_internal_group = ${cfg.group}
        ${optionalString (cfg.mailUser != null) "mail_uid = ${cfg.mailUser}"}
        ${optionalString (cfg.mailGroup != null) "mail_gid = ${cfg.mailGroup}"}

        mail_location = ${cfg.mailLocation}

        maildir_copy_with_hardlinks = yes

        auth_mechanisms = plain

        recipient_delimiter = ${cfg.recipientDelimiter}

        namespace inbox {
          inbox = yes
          ${
          optionalString (cfg.separator != null)
              "separator = ${cfg.separator}"
        }
          ${concatStringsSep "\n" (map mailboxConfig cfg.mailboxes)}
        }

        protocol imap {
          mail_plugins = $mail_plugins imap_zlib ${imapPlugins}
          mail_max_userip_connections = ${
          toString cfg.imap.maxUserIPConnections
        }
        }

        service imap {
          vsz_limit = ${toString cfg.imap.vszLimit} M
        }

        service indexer-worker {
          vsz_limit = ${toString cfg.indexer.vszLimit} M
        }
      ''

      (
        optionalString cfg.lmtp.inet.enable
          (
            let
              userString = if cfg.mailUser != null then "user = ${cfg.mailUser}" else "";
              ipv4Addresses = concatStringsSep " " cfg.lmtp.inet.ipv4Addresses;
              ipv6Addresses = concatStringsSep " " cfg.lmtp.inet.ipv6Addresses;
              mailPlugins =
                if cfg.sieveScripts != { } then
                  "mail_plugins = $mail_plugins sieve"
                else
                  "";
              saveToDetailMailbox =
                if cfg.lmtp.saveToDetailMailbox then
                  "lmtp_save_to_detail_mailbox = yes"
                else
                  "";
            in
            ''
              ${saveToDetailMailbox}

              protocol lmtp {
                ${mailPlugins}
                postmaster_address = ${cfg.lmtp.postmasterAddress}
              }

              service lmtp {
                ${userString}

                process_min_avail = 5

                inet_listener lmtp {
                  address = 127.0.0.1 ::1 ${ipv6Addresses} ${ipv4Addresses}
                  port = ${toString cfg.lmtp.inet.port}
                }
              }
            ''
          )
      )

      (
        if cfg.enablePAM then ''
          userdb {
            driver = passwd
          }

          passdb {
            driver = pam
            args = ${
            optionalString cfg.showPAMFailure "failure_show_msg=yes"
          } dovecot2
          }
        '' else ''
          service auth-worker {
            user = $default_internal_user
          }
        ''
      )

      (
        optionalString (cfg.sieveScripts != { }) ''
          plugin {
            ${
            concatStringsSep "\n"
                (
                    mapAttrsToList (to: from: "sieve_${to} = ${stateDir}/sieve/${to}")
                        cfg.sieveScripts
                  )
          }
          }
        ''
      )

      (
        optionalString cfg.antispam.enable ''
          plugin {
            sieve_plugins = sieve_imapsieve sieve_extprograms
            sieve_global_extensions = +vnd.dovecot.pipe +vnd.dovecot.environment
            sieve_pipe_bin_dir = ${stateDir}/sieve

            imapsieve_mailbox1_name = ${cfg.antispam.junkMailbox}
            imapsieve_mailbox1_causes = COPY
            imapsieve_mailbox1_before = ${stateDir}/sieve/imapsieve_mailbox1_before

            imapsieve_mailbox2_name = *
            imapsieve_mailbox2_from = ${cfg.antispam.junkMailbox}
            imapsieve_mailbox2_causes = COPY
            imapsieve_mailbox2_before = ${stateDir}/sieve/imapsieve_mailbox2_before
          }
        ''
      )

      (
        optionalString cfg.enableQuota ''
          mail_plugins = $mail_plugins quota
          service quota-status {
            executable = ${dovecotPkg}/libexec/dovecot/quota-status -p postfix
            inet_listener {
              port = ${cfg.quotaPort}
            }
            client_limit = 1
          }

          protocol imap {
            mail_plugins = $mail_plugins imap_quota
          }

          plugin {
            quota_rule = *:storage=${cfg.quotaGlobalPerUser}
            quota = maildir:User quota # per virtual mail user quota # BUG/FIXME broken, we couldn't get this working
            quota_status_success = DUNNO
            quota_status_nouser = DUNNO
            quota_status_overquota = "552 5.2.2 Mailbox is full"
            quota_grace = 10%%
          }
        ''
      )

      cfg.extraConfig
    ];
  modulesDir = pkgs.symlinkJoin {
    name = "dovecot-modules";
    paths = map (pkg: "${pkg}/lib/dovecot")
      (
        [ dovecotPkg ]
        ++ map (module: module.override { dovecot = dovecotPkg; }) cfg.modules
      );
  };
  mailboxConfig = mailbox:
    ''
      mailbox "${mailbox.name}" {
        auto = ${toString mailbox.auto}
    '' + optionalString (mailbox.specialUse != null) ''
      special_use = \${toString mailbox.specialUse}
    '' + "}";
  mailboxes = { ... }: {
    options = {
      name = mkOption {
        type = types.strMatching ''[^"]+'';
        example = "Spam";
        description = "The name of the mailbox.";
      };
      auto = mkOption {
        type = types.enum [ "no" "create" "subscribe" ];
        default = "no";
        example = "subscribe";
        description =
          "Whether to automatically create or create and subscribe to the mailbox or not.";
      };
      specialUse = mkOption {
        type = types.nullOr
          (
            types.enum [
              "All"
              "Archive"
              "Drafts"
              "Flagged"
              "Junk"
              "Sent"
              "Trash"
            ]
          );
        default = null;
        example = "Junk";
        description =
          "Null if no special use flag is set. Other than that every use flag mentioned in the RFC is valid.";
      };
    };
  };
in
{

  disabledModules = [ "services/mail/dovecot.nix" ];

  options.services.dovecot2 = {
    enable = mkEnableOption "a Dovecot 2.x IMAP server";

    protocols = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional listeners to start when Dovecot is enabled.";
    };

    imap = {
      enable = mkEnableOption "IMAP services";

      maxUserIPConnections = mkOption {
        type = types.ints.positive;
        default = 20;
        example = 5;
        description = ''
          The maximum number of IPs from which a given user can
          connect.
        '';
      };

      vszLimit = mkOption {
        type = types.ints.positive;
        default = 512;
        example = 1024;
        description = ''
          The IMAP service virtual size limit, in megabytes.
        '';
      };
    };

    user = mkOption {
      type = types.str;
      default = "dovecot2";
      description = "Dovecot user name.";
    };

    group = mkOption {
      type = types.str;
      default = "dovecot2";
      description = "Dovecot group name.";
    };

    lmtp = {

      postmasterAddress = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "postmaster@example.com";
        description = ''
          The RFC 2142 "postmaster" address for the domain for which
          Dovecot LMTP is delivering mail.
        '';
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = cfg.mailUser;
        description = ''
          This option allows you to specify under which user ID the
          LMTP service runs.

          By default, the Dovecot LMTP service runs as root. If you're
          using a pure "virtual mail" Dovecot setup, this may not be
          necessary, as in that case, the LMTP service can run as the
          virtual mail user.

          The default value of this option is the same as the
          <option>services.dovecot2.mailUser</option> option, since,
          if you are setting that option, you're likely running
          Dovecot in a pure virtual mail configuration and may benefit
          from the additional security provided by running the LMTP
          service as the virtual mail user.

          If you want the Dovecot default value, set this option to
          <literal>null</literal>.

          Note that this option is ignored unless the LMTP inet
          service is enabled.
        '';
      };

      saveToDetailMailbox = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If true, LMTP will save incoming email to the "detail"
          mailbox; that is, to the mailbox specified by the detail
          part of the envelope To: email address. For example, if this
          option is enabled and the address extension recipient
          delimiter is "+" and the incoming message is addressed to
          "bob+sales@example.com", the LMTP delivery agent will save
          the message to a mailbox named "sales", rather than to Bob's
          inbox.

          The LMTP delivery agent will also automatically create the
          detail mailbox upon delivery, if it does not already exist.
        '';
      };

      inet = {

        enable = mkEnableOption ''
          the LMTP service on one or more IP addresses.

          Note that the LMTP inet service will also be configured for
          TLS/SSL support, using the same certificates that are
          specified for the other Dovecot TLS/SSL services.
        '';

        ipv4Addresses = mkOption {
          type = types.listOf pkgs.lib.types.ipv4NoCIDR;
          default = [ ];
          example = [ "192.0.2.1" ];
          description = ''
            A list of IPv4 addresses on which the LMTP service will listen.

            Note that the LMTP service, if enabled, will always listen
            on the IPv4 loopback address, <literal>127.0.0.1</literal>
          '';
        };

        ipv6Addresses = mkOption {
          type = types.listOf pkgs.lib.types.ipv6NoCIDR;
          default = [ ];
          example = [ "2001:db8::1" ];
          description = ''
            A list of IPv6 addresses on which the LMTP service will listen.

            Note that the LMTP service, if enabled, will always listen
            on the IPv6 loopback address, <literal>::1</literal>
          '';
        };

        port = mkOption {
          type = pkgs.lib.types.port;
          default = 24;
          example = 26;
          description = ''
            The port on which the LMTP service will listen.
          '';
        };

      };

    };

    antispam = {
      enable = mkEnableOption ''
        anti-spam training with sieve, per
        https://wiki2.dovecot.org/HowTo/AntispamWithSieve.
      '';

      trashMailbox = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = "Trash";
        example = "Deleted Messages";
        description = ''
          The IMAP server's special "Trash" mailbox.
        '';
      };

      junkMailbox = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = "Junk";
        example = "Spam";
        description = ''
          The IMAP server's special "Junk" mailbox.
        '';
      };

      scripts = {
        learnHam = mkOption {
          type = types.path;
          description = ''
            The script to be run when a message is moved from the
            "Junk" mailbox to any other mailbox other than the "Trash"
            mailbox.

            See
            https://wiki2.dovecot.org/HowTo/AntispamWithSieve#Shell_scripts
            for details. You must integrate this script into your
            particular spam system.
          '';
        };

        learnSpam = mkOption {
          type = types.path;
          description = ''
            The script to be run when a message is moved from any
            mailbox to the "Junk" mailbox.

            See
            https://wiki2.dovecot.org/HowTo/AntispamWithSieve#Shell_scripts
            for details. You must integrate this script into your
            particular spam system.
          '';
        };
      };

    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "mail_debug = yes";
      description =
        "Additional entries to put verbatim into Dovecot's config file.";
    };

    configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Config file used for the whole dovecot configuration.";
      apply = v: if v != null then v else pkgs.writeText "dovecot.conf" dovecotConf;
    };

    mailLocation = mkOption {
      type = types.str;
      default = "maildir:/var/spool/mail/%u"; # Same as inbox, as postfix
      example = "maildir:~/mail:INBOX=/var/spool/mail/%u";
      description = ''
        Location that dovecot will use for mail folders. Dovecot mail_location option.
      '';
    };

    mailUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default user to store mail for virtual users.";
    };

    mailGroup = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default group to store mail for virtual users.";
    };

    createMailUser = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to automatically create the user
                given in <option>services.dovecot.user</option> and the group
                given in <option>services.dovecot.group</option>.'';
    };

    modules = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExample "[ pkgs.dovecot_pigeonhole ]";
      description = ''
        Symlinks the contents of lib/dovecot of every given package into
        /etc/dovecot/modules. This will make the given modules available
        if a dovecot package with the module_dir patch applied is being used.
      '';
    };

    sslCACert = mkOption {
      type = types.path;
      description = "Path to the server's CA certificate key.";
    };

    sslServerCert = mkOption {
      type = types.path;
      description = "Path to the server's public key.";
    };

    sslServerKey = mkOption {
      type = types.path;
      description = "Path to the server's private key.";
    };

    dhParamsFile = mkOption {
      type = types.path;
      description = "Path to the server's DH params file.";
    };

    sslCiphers = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = pkgs.lib.security.sslModernCiphers;
      example =
        "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256";
      description = ''
        Specify the list of SSL ciphers that the server will accept.
      '';
    };

    enablePAM = mkOption {
      type = types.bool;
      default = true;
      description =
        "Whether to create a own Dovecot PAM service and configure PAM user logins.";
    };

    sieveScripts = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description =
        "Sieve scripts to be executed. Key is a sequence, e.g. 'before2', 'after' etc.";
    };

    showPAMFailure = mkOption {
      type = types.bool;
      default = false;
      description =
        "Show the PAM failure message on authentication error (useful for OTPW).";
    };

    mailboxes = mkOption {
      type = types.listOf (types.submodule mailboxes);
      default = [ ];
      example = [
        {
          name = "Spam";
          specialUse = "Junk";
          auto = "create";
        }
      ];
      description = "Configure mailboxes and auto create or subscribe them.";
    };

    recipientDelimiter = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "+";
      example = "-";
      description = ''
        The detail delimiter for extended addresses, e.g.,
        "bob+sales@example.com".
      '';
    };

    separator = mkOption {
      type = types.nullOr pkgs.lib.types.nonEmptyStr;
      default = null;
      example = "/";
      description = ''
        The mailbox hierarchical separator; i.e., character that is
        used to separate a parent mailbox name from its child mailbox
        names. This is only used in the logical namespace (e.g., that
        seen by an IMAP client), <em>not</em> in the mail store
        filesystem.

        If null (the default), the logical separator will be
        determined by the mailbox format.

        <strong>Note</strong>: if you change this after users have
        created nested mailboxes, expect things to break.
      '';
    };

    enableQuota = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether to enable the dovecot quota service.";
    };

    quotaPort = mkOption {
      type = types.str;
      default = "12340";
      description = ''
        The Port the dovecot quota service binds to.
        If using postfix, add check_policy_service inet:localhost:12340 to your smtpd_recipient_restrictions in your postfix config.
      '';
    };
    quotaGlobalPerUser = mkOption {
      type = types.str;
      default = "100G";
      example = "10G";
      description =
        "Quota limit for the user in bytes. Supports suffixes b, k, M, G, T and %.";
    };

    indexer = {
      vszLimit = mkOption {
        type = types.ints.positive;
        default = 512;
        example = 1024;
        description = ''
          The indexer-worker service virtual size limit, in megabytes.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    hacknix.assertions.moduleHashes."services/mail/dovecot.nix" =
      "95fb85fd51c6c09898f44499bde5ce1fd1e3c167b4e6f6529d5cf9d2cb3ffd10";

    security.pam.services.dovecot2 = mkIf cfg.enablePAM { };

    services.dovecot2.protocols = optional cfg.imap.enable "imap"
      ++ optional cfg.lmtp.inet.enable "lmtp";

    users.users = {
      dovenull = {
        name = "dovenull";
        uid = config.ids.uids.dovenull2;
        description = "Dovecot user for untrusted logins";
        group = "dovenull";
      };
    } // optionalAttrs (cfg.user == "dovecot2") {
      dovecot2 = {
        name = "dovecot2";
        uid = config.ids.uids.dovecot2;
        description = "Dovecot user";
        group = cfg.group;
      };
    } // optionalAttrs (cfg.createMailUser && cfg.mailUser != null) {
      "${cfg.mailUser}" = {
        name = cfg.mailUser;
        description = "Virtual Mail User";
      } // optionalAttrs (cfg.mailGroup != null) { group = cfg.mailGroup; };
    };

    users.groups = optionalAttrs (cfg.group == "dovecot2") {
      dovecot2 = {
        name = "dovecot2";
        gid = config.ids.gids.dovecot2;
      };
    } // optionalAttrs (cfg.createMailUser && cfg.mailGroup != null) {
      "${cfg.mailGroup}" = { name = cfg.mailGroup; };
    } // {
      dovenull = {
        name = "dovenull";
        gid = config.ids.gids.dovenull2;
      };
    };

    environment.etc."dovecot/modules".source = modulesDir;
    environment.etc."dovecot/dovecot.conf".source = cfg.configFile;

    systemd.services.dovecot2 = {
      description = "Dovecot IMAP server";

      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ cfg.configFile ];

      serviceConfig = {
        ExecStart = "${dovecotPkg}/sbin/dovecot -F";
        ExecReload = "${dovecotPkg}/sbin/doveadm reload";
        Restart = "on-failure";
        RestartSec = "1s";
        StartLimitInterval = "1min";
        RuntimeDirectory = [ "dovecot2" ];
      };

      # When copying sieve scripts preserve the original time stamp
      # (should be 0) so that the compiled sieve script is newer than
      # the source file and Dovecot won't try to compile it.
      preStart = ''
        rm -rf ${stateDir}/sieve
      '' + optionalString (cfg.sieveScripts != { }) ''
        mkdir -p ${stateDir}/sieve
        ${concatStringsSep "\n"
          (
              mapAttrsToList
                  (
                      to: from: ''
                          if [ -d '${from}' ]; then
                            mkdir '${stateDir}/sieve/${to}'
                            cp -p "${from}/"*.sieve '${stateDir}/sieve/${to}'
                          else
                            cp -p '${from}' '${stateDir}/sieve/${to}'
                          fi
                          ${pkgs.dovecot_pigeonhole}/bin/sievec '${stateDir}/sieve/${to}'
                        ''
                    ) cfg.sieveScripts
            )}
        chown -R '${cfg.mailUser}:${cfg.mailGroup}' '${stateDir}/sieve'
      '' + optionalString cfg.antispam.enable ''
        mkdir -p ${stateDir}/sieve
        ${concatStringsSep "\n"
          (
              mapAttrsToList
                  (
                      to: from: ''
                          if [ -d '${from}' ]; then
                            mkdir '${stateDir}/sieve/${to}'
                            cp -p "${from}/"*.sieve '${stateDir}/sieve/${to}'
                          else
                            cp -p '${from}' '${stateDir}/sieve/${to}'
                          fi
                          ${pkgs.dovecot_pigeonhole}/bin/sievec '${stateDir}/sieve/${to}'
                        ''
                    ) antiSpamSieveScripts
            )}
        cp ${cfg.antispam.scripts.learnSpam} ${stateDir}/sieve/learn-spam.sh
        chmod +x ${stateDir}/sieve/learn-spam.sh
        cp ${cfg.antispam.scripts.learnHam} ${stateDir}/sieve/learn-ham.sh
        chmod +x ${stateDir}/sieve/learn-ham.sh
        chown -R '${cfg.mailUser}:${cfg.mailGroup}' '${stateDir}/sieve'
      '';
    };

    environment.systemPackages = [ dovecotPkg ];

    assertions = [
      {
        assertion = (cfg.sslServerCert == null) == (cfg.sslServerKey == null)
          && (
          cfg.sslCACert != null
            -> !(cfg.sslServerCert == null || cfg.sslServerKey == null)
        );
        message =
          "dovecot needs both sslServerCert and sslServerKey defined for working crypto";
      }
      {
        assertion = cfg.showPAMFailure -> cfg.enablePAM;
        message =
          "dovecot is configured with showPAMFailure while enablePAM is disabled";
      }
      {
        assertion = cfg.sieveScripts != { }
          -> (cfg.mailUser != null && cfg.mailGroup != null);
        message =
          "dovecot requires mailUser and mailGroup to be set when sieveScripts is set";
      }
    ];

  };

}
