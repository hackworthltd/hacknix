{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.vault-agent.auth.approle;

  agentConfig = ''
    auto_auth {
      method {
        type = "approle"
        config = {
          role_id_file_path = "${cfg.roleIdPath}"
          secret_id_file_path = "${cfg.secretIdPath}"
          remove_secret_id_file_after_reading = false
        }
      }
    }
  '';
in
{
  options.services.vault-agent.auth.approle = {
    enable = lib.mkEnableOption ''
      Vault Agent authentication via AppRole.

      This is a "mix-in" service intended for use with the
      <option>services.vault-agent</option> service, which must also
      be enabled.

      Note that this service config does not set
      <literal>use_auto_auth_token</literal> in the Vault Agent
      config, as it's not necessary for auto-renewing templated
      secrets, which is this configuration's purpose.
    '';

    roleIdPath = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      description = ''
        The path to a file containing the machine's AppRole role ID.

        Do <strong>not</strong> keep this file in the Nix store, as
        it is considered a secret.
      '';
    };

    secretIdPath = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      description = ''
        The path to a file containing the machine's AppRole secret ID.

        This secret should not be wrapped, nor should it have a
        limited number of uses. The Vault Agent will need to use it
        every time the service is restarted.

        Do <strong>not</strong> keep this file in the Nix store.

        Note that this file will <strong>not</strong> be deleted after
        use.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.vault-agent.config = agentConfig;
  };
}
