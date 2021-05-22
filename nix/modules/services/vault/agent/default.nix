{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.vault-agent;

  configFile = pkgs.writeText "vault-agent.hcl" (cfg.config + ''
    exit_after_auth = false
    pid_file = "./vault-agent.pid"

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

    config = lib.mkOption {
      type = pkgs.lib.types.lines;
      description = ''
        The Vault Agent HCL config file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.vault-agent = {
      before = (lib.optional config.services.vault.enable "vault.service");
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        vault

        # Vault appears to need this in agent mode.
        getent
      ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "30s";
        ExecStart =
          "${pkgs.vault}/bin/vault agent -config ${configFile}";
      };
    };
  };
}
