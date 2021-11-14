{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.hydra-manual-setup;
  hydraPkg = config.services.hydra.package;
in
{
  options.services.hydra-manual-setup = {
    enable = mkEnableOption ''
      the <literal>hydra-manual-setup</literal> service. Note that
      the service will only actually run if both this option and
      <literal>services.hydra</literal> are <literal>true</literal>.
    '';

    adminUser = {
      fullName = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "Hydra Admin";
        description = ''
          The full name of the Hydra admin user.
        '';
      };

      userName = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "admin";
        description = ''
          The username of the Hydra admin user in the Hydra web
          interface.
        '';
      };

      email = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "hydra@example.com";
        description = ''
          The email address of the Hydra admin user.
        '';
      };

      initialPasswordLiteral = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = literalExpression "passw0rd";
        description = ''
          The Hydra admin user's initial password, as a string
          literal.

          <strong>Note:</strong> As this password will be embedded
          in a startup script and therefore placed in the Nix store,
          you should change it as soon as possible, and probably not
          make the Hydra web service available to the public before
          doing so.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && config.services.hydra.enable) {
    systemd.services.hydra-manual-setup = rec {
      description = "Automate Hydra's initial manual setup";
      wantedBy = [ "multi-user.target" ];
      requires = [ "hydra-init.service" ];
      after = [ "hydra-init.service" ];
      environment = mkForce config.systemd.services.hydra-init.environment;
      script =
        ''
          if [ ! -e ~hydra/.manual-setup-is-complete-v1 ]; then
            ${hydraPkg}/bin/hydra-create-user ${cfg.adminUser.userName} --full-name "${cfg.adminUser.fullName}" --email-address ${cfg.adminUser.email} --role admin --password "${cfg.adminUser.initialPasswordLiteral}"
            touch ~hydra/.manual-setup-is-complete-v1
          fi
        '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
