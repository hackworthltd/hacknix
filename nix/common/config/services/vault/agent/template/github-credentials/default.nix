{ config
, pkgs
, lib
, inputs
, ...
}:
let
  cfg = config.services.vault-agent.template.github-credentials;
  enabled = cfg != { };

  gitCredentialsFile = user: "${user.dir}/.git-credentials";

  templateContents = user: lib.concatMapStrings
    (creds: ''
      https://${creds.username}:{{ with secret "${creds.vaultPath}" }}{{ .Data.token }}{{ end }}@${creds.hostname}
    ''
    )
    (lib.mapAttrsToList (_: creds: creds) user.credentials);

  templateFile = user: pkgs.writeText "git-credentials.ctmpl" (templateContents user);

  fixGitCredentialsFileOwner = user: pkgs.writeShellScript "fix-git-credentials-file-owner" ''
    ${pkgs.coreutils}/bin/chown ${user.owner}:${user.group} ${gitCredentialsFile user}
  '';

  create_dir = user: if user.createDir then "true" else "false";
  error_on_missing_key = user: if user.exitOnMissingKey then "true" else "false";

  listOfUsers = lib.mapAttrsToList (_: users: users) cfg;

  vaultConfig = lib.concatMapStrings
    (user: ''
      template {
        destination = "${gitCredentialsFile user}"
        source = "${templateFile user}"
        perms = "0400"
        create_dest_dirs = ${create_dir user}
        error_on_missing_key = ${error_on_missing_key user}
        command = "${fixGitCredentialsFileOwner user}"
      }
    ''
    )
    listOfUsers;

  creds = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = name;
        example = "dhess";
        description = ''
          A short descriptive name for the local user.
        '';
      };

      vaultPath = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "github/token/dhess";
        description = ''
          The Vault GitHub secrets engine path for the GitHub auth
          token for these credentials.
        '';
      };

      username = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "orgname";
        description = ''
          The GitHub username for these credentials. Note that in most
          cases, you'll want to use the GitHub name of the
          organization in which the GitHub app is installed. You can
          create user-scoped credentials by varying the attributes on
          the configured <option>vaultPath</option> option.
        '';
      };

      hostname = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = "github.com";
        example = "github.orgname.org";
        description = ''
          The hostname of the GitHub instance where the GitHub app is
          installed. Unless you're using GitHub Enterprise, you should
          keep the default value, which is
          <literal>github.com</literal>.

          Do not include the <literal>https://</literal> URL prefix.
          This module adds that prefix automatically.
        '';
      };
    };
  };

  user = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = name;
        example = "dhess";
        description = ''
          A short descriptive name for the local user.
        '';
      };

      dir = lib.mkOption {
        type = pkgs.lib.types.nonStorePath;
        example = "/home/dhess";
        description = ''
          The directory where the <literal>.git-credentials</literal>
          file will be persisted.

          Note that, unfortunately, Vault can't handle paths like
          <literal>~user</literal>, so if you want to set this to a
          particular user's home directory, you'll need to specify the
          literal pathname here.
        '';
      };

      createDir = lib.mkOption {
        type = pkgs.lib.types.bool;
        default = false;
        example = true;
        description = ''
          If true, Vault Agent will create the directory whose path is
          given in the <option>dir</option> option.

          Usually, as the <literal>.git-credentials</literal> file
          will be created in the user's home directory, you'll want to
          set this value to <literal>false</literal>, its default
          value.
        '';
      };

      owner = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "dhess";
        description = ''
          The filesystem owner of the
          <literal>.git-credentials</literal> config file that Vault
          Agent will persist to disk.
        '';
      };

      group = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "dhess";
        description = ''
          The filesystem group of the
          <literal>.git-credentials</literal> config file that Vault
          Agent will persist to disk.
        '';
      };

      exitOnMissingKey = lib.mkOption {
        type = pkgs.lib.types.bool;
        default = true;
        example = false;
        description = ''
          If true (the default), a failure to render the
          <literal>.git-credentials</literal> file will cause Vault
          Agent to exit with an error. This is a safeguard against
          silent failure. As this is extremely unlikely to occur in
          normal operation, you should probably keep the default
          value.
        '';
      };

      credentials = lib.mkOption {
        type = pkgs.lib.types.attrsOf (pkgs.lib.types.submodule creds);
        default = { };
      };
    };
  };

in
{
  options.services.vault-agent.template.github-credentials = lib.mkOption {
    type = pkgs.lib.types.attrsOf (pkgs.lib.types.submodule user);
    default = { };
    example = {
      dhess = {
        dir = "/home/dhess";
        owner = "dhess";
        group = "dhess";
        credentials = {
          github = {
            vaultPath = "github/token/dhess";
            username = "hackworthltd";
          };
        };
      };
    };
    description = ''
      Configure per-user git credentials using Vault and the
      https://github.com/martinbaillie/vault-plugin-secrets-github
      plugin.
    '';
  };

  config = lib.mkIf enabled {
    services.vault-agent.config = vaultConfig;
    programs.git.enable = true;
    programs.git.config.credential.helper = "store";
  };
}
