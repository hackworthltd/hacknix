{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.vault-agent;

  ca_cert = lib.optionalString (cfg.server.caCertPath != null) ''
    ca_cert = "${cfg.server.caCertPath}"
  '';
  configFile = pkgs.writeText "vault-agent.hcl" (cfg.config + ''
    exit_after_auth = false
    pid_file = "${cfg.dataDir}/vault-agent.pid"

    vault {
      address = "${cfg.server.address}"
      tls_skip_verify = ${if cfg.server.tlsSkipVerify then "true" else "false"}
      ${ca_cert}
    }
  '');
in
{
  options.services.vault-agent = {
    enable = lib.mkEnableOption ''
      a Vault Agent for local services on this host.

      Note that, by default, this agent will not listen for incoming
      connections. You should not enable that unless you know what
      you're doing; this Vault Agent service is intended for use with
      machine services only.
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
      default = "";
      description = ''
        The Vault Agent HCL config file.
      '';
    };

    dataDir = lib.mkOption {
      readOnly = true;
      default = "/var/lib/vault-agent";
      description = "The working directory for the agent";
      type = pkgs.lib.types.str;
    };

    logFile = lib.mkOption {
      default = "/var/log/vault-agent.log";
      example = "/var/lib/vault-agent/vault-agent.log";
      description = "The Vault Agent logfile";
      type = pkgs.lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.vault-agent = {
      path = with pkgs; [
        getent # Vault appears to need this in agent mode.
        vault
      ];
      environment = {
        HOME = cfg.dataDir;
      };

      script = ''
        ${pkgs.coreutils}/bin/install -o root -g wheel -m 0750 -d ${cfg.dataDir}
        /bin/wait4path ${pkgs.vault}/bin/vault
        ${cfg.preCommands}
        exec ${pkgs.vault}/bin/vault agent -config ${configFile}
      '';

      serviceConfig = {
        ProcessType = "Interactive";
        ThrottleInterval = 30;
        KeepAlive = true;
        StandardErrorPath = cfg.logFile;
        StandardOutPath = cfg.logFile;
        Label = "com.hashicorp.vault-agent";
      };
    };
  };
}
