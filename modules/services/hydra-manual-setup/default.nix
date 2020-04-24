{ config, lib, pkgs, ... }:

with lib;

let

  deployed-pw = config.hacknix.keychain.keys.hydra-manual-setup-initial-pw.path;
  deployed-bckey = config.hacknix.keychain.keys.hydra-manual-setup-bckey.path;
  cfg = config.services.hydra-manual-setup;

  hydraPkg = config.services.hydra.package;

in {
  options = {

    services.hydra-manual-setup = {

      description = ''
        This service, when enabled along with the
        <literal>hydra</literal> service, will do all of the initial
        Hydra setup that normally needs to be done manually.
        Specifically, it will create the admin user and set the admin
        user's initial password in a relatively secure manner; see
        <option>adminUser.initialPassword</option> for details.

        The service will also copy the server's binary cache
        public/private keypair to a specified location on the Hydra
        server's filesystem.

        This service will only run once (successfully) and will
        effectively be a no-op from that point on.
      '';

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
          example = literalExample "passw0rd";
          description = ''
            The Hydra admin user's initial password, as a string
            literal. Note that this secret will not copied to the Nix
            store.

            Note that the <command>hydra-create-user</command> command
            used to create this user only takes passwords as strings
            on the command line, so there is a small chance that an
            attacker who is on the Hydra master system could see the
            <command>hydra-create-user</command> command as it runs
            using a process tool such as <command>ps</command>, and
            therefore also see the initial admin user password
            command-line argument.

            To be fair, the exact same scenario applies if you run the
            <command>hydra-create-user</command> command by hand, so
            this risk is not unique to this service and is inherent to
            <command>hydra-create-user</command>. In any case, to be
            truly safe, you should change this initial password by
            logging into the Hydra web console and changing it there.
          '';
        };

      };

      binaryCacheKey = {

        publicKeyFile = mkOption {
          type = types.path;
          example = ./hydra-bc.public;
          description = ''
            A path to a file that contains the Hydra server's binary
            cache public key.

            You can create the public/private keypair with the command:

            <command>nix-store --generate-binary-cache-key hydra.example.com-1 hydra-example.com-1/secret hydra-example.com-1/public</command>

            The service will copy the key to the file
            <literal>${binaryCacheDir}/public</literal>.
          '';
        };

        privateKeyLiteral = mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = literalExample "<bckey>";
          description = ''
            The Hydra server's binary cache private key, as a string
            literal. Note that this secret will not copied to the Nix
            store.

            However, the service will copy the deployed secret to the
            file <literal>${binaryCacheDir}/secret</literal> so that
            it is available after reboots.
          '';
        };

        directory = mkOption {
          type = types.path;
          example = "/etc/nix/hydra-bc";
          description = ''
            The public and private key files will be installed in this
            directory as <literal>directory/public</literal> and
            <literal>directory/secret</literal>, respectively.
          '';
        };

      };

    };

  };

  config = mkIf (cfg.enable && config.services.hydra.enable) {

    hacknix.keychain.keys = {
      hydra-manual-setup-initial-pw = {
        text = cfg.adminUser.initialPasswordLiteral;
      };
      hydra-manual-setup-bckey = {
        text = cfg.binaryCacheKey.privateKeyLiteral;
      };
    };

    systemd.services.hydra-manual-setup = rec {

      description = "Automate Hydra's initial manual setup";
      wantedBy = [ "multi-user.target" ];
      wants = [
        "hydra-manual-setup-initial-pw-key.service"
        "hydra-manual-setup-bckey-key.service"
      ];
      requires = [ "hydra-init.service" ];
      after = [ "hydra-init.service" ] ++ wants;

      environment = mkForce config.systemd.services.hydra-init.environment;
      script = let bcKeyDir = cfg.binaryCacheKey.directory;
      in ''
        if [ ! -e ~hydra/.manual-setup-is-complete-v1 ]; then
          HYDRA_PW=$(cat "${deployed-pw}")
          ${hydraPkg}/bin/hydra-create-user ${cfg.adminUser.userName} --full-name "${cfg.adminUser.fullName}" --email-address ${cfg.adminUser.email} --role admin --password $HYDRA_PW

          install -d -m 551 "${bcKeyDir}"
          cp "${deployed-bckey}" "${bcKeyDir}/secret"
          chmod 0440 "${bcKeyDir}/secret"
          cp "${cfg.binaryCacheKey.publicKeyFile}" "${bcKeyDir}/public"
          chmod 0444 "${bcKeyDir}/public"
          chown -R hydra:hydra "${bcKeyDir}"

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
