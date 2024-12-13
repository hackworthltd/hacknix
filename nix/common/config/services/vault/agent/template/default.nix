{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.services.vault-agent.templates;
  enabled = cfg != { };

  defaultGroup = if pkgs.stdenv.isDarwin then "wheel" else "root";

  error_on_missing_key = secret: if secret.exitOnMissingKey then "true" else "false";

  listOfSecrets = lib.mapAttrsToList (_: secrets: secrets) cfg;
  vaultConfig = lib.concatMapStrings (
    secret:
    let
      templateFile = pkgs.writeText "${secret.name}.ctmpl" secret.template;
      command = pkgs.writeShellScript "${secret.name}-command" secret.command;
    in
    ''
      template {
        destination = "${secret.destination}"
        source = "${templateFile}"
        perms = "${secret.permissions}"
        create_dest_dirs = false
        error_on_missing_key = ${error_on_missing_key secret}
        command = "${command}"
      }
    ''
  ) listOfSecrets;

  mkdirsCmds = lib.concatMapStringsSep "\n" (
    secret:
    "${pkgs.coreutils}/bin/install -d -m ${secret.createDir.permissions} -o ${secret.createDir.owner} -g ${secret.createDir.group} `${pkgs.coreutils}/bin/dirname ${secret.destination}`"
  ) (builtins.filter (secret: secret.createDir.enable) listOfSecrets);

  secrets =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          default = name;
          example = "aws-token";
          description = ''
            A short descriptive name for the generated secret.
          '';
        };

        destination = lib.mkOption {
          type = pkgs.lib.types.nonStorePath;
          example = "/root/.aws/credentials";
          description = ''
            The path to the file that will be created by Vault Agent,
            containing the secret.

            Note that, unfortunately, Vault can't handle paths like
            <literal>~user</literal>, so if you want to set this to a
            particular user's home directory, you'll need to specify the
            literal pathname here.
          '';
        };

        template = lib.mkOption {
          type = pkgs.lib.types.lines;
          example = lib.literalExpression ''
            token {{ with secret "github/token/foo" }}{{ .Data.token }}{{ end }}
          '';
          description = ''
            The contents of the Vault Agent template for the secret.
          '';
        };

        permissions = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          default = "0400";
          example = "0644";
          description = ''
            The permissions of the secret's destination file.
          '';
        };

        command = lib.mkOption {
          type = pkgs.lib.types.lines;
          example = lib.literalExpression ''
            chown alice:alice /path/to/secret
          '';
          description = ''
            A command to run after Vault Agent writes the secret to the
            destination file.
          '';
        };

        exitOnMissingKey = lib.mkOption {
          type = pkgs.lib.types.bool;
          default = true;
          example = false;
          description = ''
            If true (the default), a failure to render the template to
            the destination file will cause Vault Agent to exit with an
            error. This is a safeguard against silent failure.
          '';
        };

        createDir = {
          enable = lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
            example = false;
            description = ''
              If true (the default), the Vault Agent service will create
            '';
          };

          owner = lib.mkOption {
            type = pkgs.lib.types.nonEmptyStr;
            default = "root";
            example = "alice";
            description = ''
              The filesystem owner of the secret file's directory.

              This option is only used if
              <option>createDir.enable</option> is true.
            '';
          };

          group = lib.mkOption {
            type = pkgs.lib.types.nonEmptyStr;
            default = defaultGroup;
            example = "alice";
            description = ''
              The filesystem group of the secret file's directory.

              This option is only used if
              <option>createDir.enable</option> is true.
            '';
          };

          permissions = lib.mkOption {
            type = pkgs.lib.types.nonEmptyStr;
            default = "0700";
            example = "0755";
            description = ''
              The permissions of the secret file's directory.
            '';
          };
        };
      };
    };
in
{
  options.services.vault-agent.templates = lib.mkOption {
    type = pkgs.lib.types.attrsOf (pkgs.lib.types.submodule secrets);
    default = { };
    example = {
      access-tokens = {
        destination = "/home/dhess/.config/nix.conf";
        template = ''
          access-tokens = github.com={{ with secret "github/token/repos" }}{{ .Data.token }}{{ end }}
        '';
        command = ''
          ${pkgs.coreutils}/bin/chmod dhess:dhess /home/dhess/.config/nix.conf
        '';
        createDir = {
          owner = "dhess";
          group = "dhess";
        };
      };
    };
    description = "Configure Vault Agent templates.";
  };

  config = lib.mkIf enabled {
    services.vault-agent.config = vaultConfig;
    services.vault-agent.preCommands = mkdirsCmds;
  };
}
