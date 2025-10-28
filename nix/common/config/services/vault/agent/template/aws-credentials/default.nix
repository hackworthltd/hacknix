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

  credentialsFile = creds: "${creds.dir}/credentials";

  awsTemplate =
    creds:
    pkgs.writeText "aws.credentials.ctmpl" ''
      [${creds.awsProfile}]
      {{ with secret "${creds.vaultPath}" }}aws_access_key_id={{ .Data.AWS_ACCESS_KEY_ID }}
      aws_secret_access_key={{ .Data.AWS_SECRET_ACCESS_KEY }}
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
          example = "secret/aws/credentials";
          description = ''
            The Vault path where the secret containing the credentials is stored.

            Typically this will be a KV store path containing static credentials.
            For genuine AWS credentials, it's safer to use Vault's support for
            AWS STS credentials. In that case, prefer the
            <literal>aws-sts-credentials</literal> Vault agent template over this one.
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
        vaultPath = "secret/aws/nix-binary-cache";
        dir = "/root/.aws";
        owner = "root";
        group = "root";
      };
    };
    description = "Configure AWS credentials templates.";
  };

  config = lib.mkIf enabled {
    services.vault-agent.config = vaultConfig;
    services.vault-agent.preCommands = mkdirsCmds;
  };
}
