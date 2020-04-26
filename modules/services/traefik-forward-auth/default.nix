{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.traefik-forward-auth;

  user = "traefik-forward-auth";
  group = "traefik-forward-auth";

  secretsFile =
    config.hacknix.keychain.keys."traefik-forward-auth-secrets".path;

  keyDir = "/var/lib/traefik-forward-auth";

  configFile = pkgs.writeText "traefik-forward-auth.conf" (cfg.literalConfig
    + ''
      providers.oidc.issuer-url = ${cfg.oidc.issuerURL}
      providers.oidc.client-id = ${cfg.oidc.clientID}
    '');

in {
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

    signingSecretLiteral = mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "vjT165sqskqrm0jU";
      description = ''
        A random string that serves as a signing secret for
        communicating with clients. This is only used by
        traefik-forward-auth and need not be shared with any other
        service -- just generate a random string and specify it here.

        This secret will be written to a file that is securely
        deployed to the host. It will not be written to the Nix store.
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

      clientSecretLiteral = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "<private key>";
        description = ''
          The OIDC client secret, provided by your OIDC provider for
          this application.

          This key will be written to a file that is securely
          deployed to the host. It will not be written to the Nix
          store.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.traefik-forward-auth = {
      description = "traefik authentication middleware";

      after = [ "network-online.target" ];
      wants = [ "traefik-forward-auth-secrets-key.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ secretsFile ];

      unitConfig = {
        StartLimitIntervalSec = 0;
        StartLimitBurst = 0;
      };

      serviceConfig = {
        User = user;
        Group = group;

        ExecStart =
          "${pkgs.traefik-forward-auth}/bin/traefik-forward-auth --config=${configFile} --config=${secretsFile}";
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

    systemd.tmpfiles.rules = [ "d '${keyDir}' 0700 ${user} ${group} - -" ];

    hacknix.keychain.keys."traefik-forward-auth-secrets" = {
      inherit user group;
      destDir = keyDir;
      permissions = "0400";
      text = ''
        secret = ${cfg.signingSecretLiteral}
        providers.oidc.client-secret = ${cfg.oidc.clientSecretLiteral}
      '';
    };

    users.users.${user} = {
      inherit group;
      isSystemUser = true;
    };

    users.groups.${group} = { };
  };
}
