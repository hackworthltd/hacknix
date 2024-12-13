{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.vault-agent;

  ca_cert = lib.optionalString (cfg.server.caCertPath != null) ''
    ca_cert = "${cfg.server.caCertPath}"
  '';
  configFile = pkgs.writeText "vault-agent.hcl" (
    cfg.config
    + ''
      exit_after_auth = false
      pid_file = "./vault-agent.pid"

      vault {
        address = "${cfg.server.address}"
        tls_skip_verify = ${if cfg.server.tlsSkipVerify then "true" else "false"}
        ${ca_cert}
      }
    ''
  );

  # This directory isn't actually used for anything, but the agent
  # expects it to exist and for the `HOME` env var to be set, anyway.
  homeDir = "/var/lib/vault-agent";
in
{
  options.services.vault-agent = {
    enable = lib.mkEnableOption ''
      a Vault Agent for local services on this host.
    '';

    server = {
      address = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "https://vault.example.com";
        description = ''
          The URL of the upstream Vault server.
        '';
      };

      caCertPath = lib.mkOption {
        type = pkgs.lib.types.nullOr pkgs.lib.types.path;
        default = null;
        example = "/etc/ssl/vault-ca.pem";
        description = ''
          A path on the target machine to the CA certificate used to
          validate TLS connections to the upstream Vault server.
        '';
      };

      tlsSkipVerify = lib.mkEnableOption ''
        TLS certificate verification against the upstream server's
        certificates.
      '';
    };

    preCommands = lib.mkOption {
      type = pkgs.lib.types.lines;
      default = "";
      description = ''
        Extra commands to run before starting Vault Agent.
      '';
    };

    config = lib.mkOption {
      type = pkgs.lib.types.lines;
      description = ''
        The Vault Agent HCL config file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${homeDir}                0700 root root -  -"
    ];

    systemd.services.vault-agent = {
      before = (lib.optional config.services.vault.enable "vault.service");
      wantedBy = [ "multi-user.target" ];

      environment.HOME = homeDir;

      path = with pkgs; [
        vault

        # Vault appears to need this in agent mode.
        getent
      ];

      script = ''
        ${cfg.preCommands}
        ${pkgs.vault}/bin/vault agent -config ${configFile}
      '';

      serviceConfig = {
        Restart = "always";
        RestartSec = "30s";
      };
    };
  };
}
