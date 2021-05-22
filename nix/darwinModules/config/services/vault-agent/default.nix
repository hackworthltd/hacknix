{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.vault-agent;

  configFile = pkgs.writeText "vault-agent.hcl" (cfg.config + ''
    auto_auth {
      method {
        type = "approle"
        config = {
          role_id_file_path = "${cfg.approle.roleIdPath}"
          secret_id_file_path = "${cfg.approle.secretIdPath}"
          remove_secret_id_file_after_reading = false
        }
      }
    }

    exit_after_auth = false
    pid_file = "${cfg.dataDir}/vault-agent.pid"

    vault {
      address = "${cfg.server.address}"
      tls_skip_verify = ${if cfg.server.tlsSkipVerify then "true" else "false"}
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

      tlsSkipVerify = lib.mkEnableOption ''
        TLS certificate verification against the upstream server's
        certificates.
      '';
    };

    approle = {
      roleIdPath = lib.mkOption {
        readOnly = true;
        type = pkgs.lib.types.nonStorePath;
        default = "/var/lib/vault-agent/role-id";
        description = ''
          The path to a file containing the machine's AppRole role ID.

          Do <strong>not</strong> keep this file in the Nix store, as
          it is considered a secret.
        '';
      };

      secretIdPath = lib.mkOption {
        readOnly = true;
        type = pkgs.lib.types.nonStorePath;
        default = "/var/lib/vault-agent/secret-id";
        description = ''
          The path to a file containing the machine's AppRole secret ID.

          This secret should not be wrapped, nor should it have a
          limited number of uses. The Vault Agent will need to use it
          every time the service is restarted.

          Do <strong>not</strong> keep this file in the Nix store.
        '';
      };
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
        /usr/bin/install -o root -g wheel -m 0750 -d ${cfg.dataDir}
        /bin/wait4path ${pkgs.vault}/bin/vault
        ${cfg.preCommands}
        exec ${pkgs.vault}/bin/vault agent -config ${configFile}
      '';

      serviceConfig = {
        ProcessType = "Interactive";
        ThrottleInterval = 30;
        KeepAlive = true;
        StandardErrorPath = "${cfg.dataDir}/vault-agent.log";
        StandardOutPath = "${cfg.dataDir}/vault-agent.log";
        Label = "com.hashicorp.vault-agent";
      };
    };

    system.activationScripts.postActivation.text = ''
      if [ -f ${cfg.approle.roleIdPath} ]; then
        printf "Setting secure permissions on Vault Agent AppRole role ID file..."
        chown root:wheel ${cfg.approle.roleIdPath}
        chmod 0440 ${cfg.approle.roleIdPath}
        echo "done"
      else
        echo "WARNING: Vault Agent AppRole role ID file is missing. Vault Agent will fail to start."
      fi

      if [ -f ${cfg.approle.secretIdPath} ]; then
        printf "Setting secure permissions on Vault Agent AppRole secret ID file..."
        chown root:wheel ${cfg.approle.secretIdPath}
        chmod 0440 ${cfg.approle.secretIdPath}
        echo "done"
      else
        echo "WARNING: Vault Agent AppRole secret ID file is missing. Vault Agent will fail to start."
      fi
    '';
  };
}
