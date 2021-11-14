{ config, lib, pkgs, ... }:

with lib;
let
  gcfg = config.services.service-status-email;
  emailScript = pkgs.writeScript "service-status-email" ''
    #!${pkgs.stdenv.shell}

    FQDN=`${pkgs.nettools}/bin/hostname -f`

    ${gcfg.sendmailPath} -t <<MAILEND
    To: $1
    From: systemd <root@$FQDN>
    Subject: $2 status ($FQDN)
    Content--Transfer-Encoding: 8bit
    Content-Type: text/plain; charset=UTF-8

    $(systemctl status --full "$2")

    MAILEND
  '';
in
{
  options = {
    services.service-status-email = {

      enable = mkEnableOption ''
        one-shot systemd units which, when started, will send
        email to a given address, where the body of the email is the
        status of a given job.


        In order for this service to function, you must also
        configure a working mail delivery agent on the host.
      '';

      sendmailPath = mkOption {
        type = types.path;
        default = "/run/wrappers/bin/sendmail";
        description = ''
          The path to the <literal>sendmail</literal> executable you
          want to use. The default value is the NixOS default
          <literal>sendmail</literal>.
        '';
      };

      recipients = mkOption {
        type = types.attrsOf
          (
            types.submodule
              (
                {
                  options = {
                    address = mkOption {
                      type = pkgs.lib.types.nonEmptyStr;
                      example = "root@example.com";
                      description = ''
                        The actual email address to which the status email
                        will be sent.
                      '';
                    };
                  };
                }
              )
          );

        default = { };

        example = literalExpression ''
          {
            root = { address = "root"; };
            hostmaster = { address = "hostmaster@example.com"; };
            emerg = { address = "pager@example.net"; };
          }
        '';

        description = ''
          A set of logical names and their corresponding email
          addresses For each name <literal><em>name</em></literal> in
          the set, a service named
          <literal>status-email-<em>name<em>@.service</literal> will
          be created.

          Then, to send an email to the
          <literal><em>name</em></literal>'s corresponding email
          address <literal><em>addr</em></literal> with the status of
          the <literal>systemd</literal> service named
          <literla><em>svc</em></literal>, simply start the service
          named
          <literal>status-email-<em>name</em>@<em>svc</em>.service</literal>.

          Note that the correspondence between each
          <literal><em>name</em></literal> and its address
          <literal><em>addr</em></literal> is arbitrary. The only
          requirements are that <literal><em>name</em></literal> is a
          valid <literal>systemd</literal> service name substring, and
          that <literal><em>addr</em></literal> is a valid email
          address for the host on which the service is running.
        '';
      };

    };
  };

  config = mkIf gcfg.enable {
    systemd.services = mapAttrs'
      (
        name: cfg:
          nameValuePair "status-email-${name}@" {
            description = "Service status email for %i to ${cfg.address}";

            serviceConfig = {
              ExecStart = "${emailScript} ${cfg.address} %i";
              Type = "oneshot";
              User = "nobody";
              Group = "systemd-journal";
            };
          }
      )
      gcfg.recipients;
  };

  meta.maintainers = lib.maintainers.dhess;

}
