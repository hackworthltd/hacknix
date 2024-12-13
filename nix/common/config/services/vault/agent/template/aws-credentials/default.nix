{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.services.vault-agent.template.aws-credentials;
  enabled = cfg != { };

  # A limitation of AWS STS tokens.
  maxTTL = 60 * 60 * 12;

  credentialsFile = creds: "${creds.dir}/credentials";

  awsTemplate =
    creds:
    pkgs.writeText "aws.credentials.ctmpl" ''
      [${creds.awsProfile}]
      {{ with secret "${creds.vaultPath}" "ttl=${builtins.toString creds.tokenTTL}" }}aws_access_key_id={{ .Data.access_key }}
      aws_secret_access_key={{ .Data.secret_key }}
      aws_session_token={{ .Data.security_token }}{{ end }}
    '';

  # Note: while there is some chance of a race condition here between
  # the time when Vault Agent writes the credentials file and it
  # executes this script to "fix" the file's ownership, I expect in
  # practice that Vault Agent does not actually try to change the
  # owner when it writes the file, so in reality, this race should
  # only occur upon first launch.
  fixCredsOwner =
    creds:
    pkgs.writeShellScript "fix-aws-credentials-owner" ''
      ${pkgs.coreutils}/bin/chown ${creds.owner}:${creds.group} ${credentialsFile creds}
    '';

  error_on_missing_key = creds: if creds.exitOnMissingKey then "true" else "false";

  listOfCreds = lib.mapAttrsToList (_: creds: creds) cfg;
  vaultConfig = lib.concatMapStrings (creds: ''
    template {
      destination = "${credentialsFile creds}"
      source = "${awsTemplate creds}"
      perms = "0400"
      create_dest_dirs = false
      error_on_missing_key = ${error_on_missing_key creds}
      command = "${fixCredsOwner creds}"
    }
  '') listOfCreds;

  mkdirsCmds = lib.concatMapStringsSep "\n" (
    creds: "${pkgs.coreutils}/bin/install -d -m 0700 -o ${creds.owner} -g ${creds.group} ${creds.dir}"
  ) listOfCreds;

  assertions = lib.flatten (
    map (creds: [
      {
        assertion = (creds.tokenTTL <= 60 * 60 * 12);
        message = "`services.vault-agent.template.aws-credentials.${creds.name}.tokenTTL` is ${builtins.toString creds.tokenTTL}, but must be <= ${builtins.toString maxTTL}";
      }
    ]) listOfCreds
  );

  credentials =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          default = name;
          example = "binary-cache";
          description = ''
            A short descriptive name for the generated credentials.
          '';
        };

        vaultPath = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "aws/sts/rolename";
          description = ''
            The Vault AWS secrets engine path for the generated AWS
            credentials.
          '';
        };

        awsProfile = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          default = "default";
          example = "hydra";
          description = ''
            The AWS profile for which to configure the credentials.
          '';
        };

        dir = lib.mkOption {
          type = pkgs.lib.types.nonStorePath;
          example = "/root/.aws";
          description = ''
            The directory where the AWS credentials will be persisted.
            In this directory, this module will persist the AWS
            credentials in a file whose name is
            <literal>credentials</literal>.

            Note that, unfortunately, Vault can't handle paths like
            <literal>~user</literal>, so if you want to set this to a
            particular user's home directory, you'll need to specify the
            literal pathname here.
          '';
        };

        owner = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "hydra-queue-runner";
          description = ''
            The filesystem owner of the credentials file that Vault
            Agent will persist to disk.
          '';
        };

        group = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "hydra";
          description = ''
            The filesystem group of the credentials file that Vault
            Agent will persist to disk.
          '';
        };

        tokenTTL = lib.mkOption {
          type = pkgs.lib.types.int;
          default = maxTTL;
          example = 60 * 60 * 2;
          description = ''
            The TTL of the generated AWS credentials, in seconds. Note
            that due to the mechanism used to generate these credentials,
            ${builtins.toString maxTTL} is the maximum TTL.

            Vault Agent will take care of renewing the credentials as
            they get close to expiry. Shorter values are better for
            security, but on the other hand, they also generate a higher
            load on the Vault server and increase the chance of failed
            AWS operations during any potential Vault downtime. The
            default value is probably best in most cases.
          '';
        };

        exitOnMissingKey = lib.mkOption {
          type = pkgs.lib.types.bool;
          default = true;
          example = false;
          description = ''
            If true (the default), a failure to render the AWS credentials
            will cause Vault Agent to exit with an error. This is a
            safeguard against silent failure. As this is extremely
            unlikely to occur in normal operation, you should probably
            keep the default value.
          '';
        };
      };
    };

in
{
  options.services.vault-agent.template.aws-credentials = lib.mkOption {
    type = pkgs.lib.types.attrsOf (pkgs.lib.types.submodule credentials);
    default = { };
    example = {
      binary-cache = {
        vaultPath = "aws/sts/nix-binary-cache";
        dir = "/root/.aws";
        owner = "root";
        group = "root";
      };
    };
    description = "Configure AWS credentials templates.";
  };

  config = lib.mkIf enabled {
    inherit assertions;
    services.vault-agent.config = vaultConfig;
    services.vault-agent.preCommands = mkdirsCmds;
  };
}
