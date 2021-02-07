{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.traefik-forward-auth;
  user = "traefik-forward-auth";
  group = "traefik-forward-auth";
  configFile = pkgs.writeText "traefik-forward-auth.conf"
    (
      cfg.literalConfig
      + ''
        providers.oidc.issuer-url = ${cfg.oidc.issuerURL}
        providers.oidc.client-id = ${cfg.oidc.clientID}
      ''
    );
in
{
  meta.maintainers = lib.maintainers.dhess;

  options.services.traefik-forward-auth = {
    enable = mkEnableOption ''
      the traefik-forward-auth service.

      The service listens on TCP port 4181.

      Currently, only OIDC providers are supported.
    '';

    literalConfig = mkOption {
      example = "";
      type = types.lines;
      description = ''
        The contents of the traefik-forward-auth config file.

        This file will be written to the Nix store. Do <em>not</em>
        specify secrets in this file. Use the
        <option>services.traefik-forward-auth.signingSecret</option>
        and <option>services.traefik-forward-auth.oidc</option>
        options to specify secrets; these options take precautions to
        prevent secrets from being written to the Nix store.
      '';
    };

    oidc = {
      clientID = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        description = ''
          Your OIDC client ID. Note that this value is not a secret.
        '';
      };

      issuerURL = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "example.okta.com";
        description = ''
          The OIDC issuer URL.
        '';
      };
    };

    secretsFile = mkOption {
      type = pkgs.lib.types.nonStorePath;
      example = "/var/lib/keys/traefik-forward-auth.secrets";
      description = ''
        A path to the file containing the traefik-forward-auth server
        secrets.

        One line in the file should read <literal>secret =
        signing-secret</literal>, where
        <literal>signing-secret</literal> is a random string that
        serves as a signing secret for communication with clients.
        This is only used by the service and need not be shared with
        any other service. It suffices to generate a random string
        with no whitespace.

        The other line in the file should read
        <literal>providers.oidc.client-secret = oidc-secret</literal>,
        where <literal>oidc-secret</literal> is the OIDC client secret
        provided by your OIDC provider for the application served
        behind the traefik-forward-auth service.

        Do not store this file in the Nix store!
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.traefik-forward-auth = {
      description = "traefik authentication middleware";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ cfg.secretsFile ];

      unitConfig = {
        StartLimitIntervalSec = 0;
        StartLimitBurst = 0;
      };

      serviceConfig = {
        User = user;
        Group = group;

        ExecStart =
          "${pkgs.traefik-forward-auth}/bin/traefik-forward-auth --config=${configFile} --config=${cfg.secretsFile}";
        Restart = "on-failure";

        AmbientCapabilities = "cap_net_bind_service";
        CapabilityBoundingSet = "cap_net_bind_service";
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "full";
      };
    };

    users.users.${user} = {
      inherit group;
      isSystemUser = true;
    };
    users.groups.${group} = { };
  };
}
