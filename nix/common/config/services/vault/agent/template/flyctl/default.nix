{ config
, pkgs
, lib
, inputs
, ...
}:
let
  cfg = config.services.vault-agent.template.flyctl;
  enabled = cfg != { };

  template = creds: pkgs.writeText "config-file.ctmpl" ''
    access_token: {{ with secret "${creds.vaultPath}" }}"{{ .Data.data.token }}"{{ end }}
  '';

  fixConfigFileOwner = creds: pkgs.writeShellScript "fix-config-file-owner" ''
    ${pkgs.coreutils}/bin/chown ${creds.owner}:${creds.group} ${creds.path}
  '';

  error_on_missing_key = creds: if creds.exitOnMissingKey then "true" else "false";

  listOfCreds = lib.mapAttrsToList (_: creds: creds) cfg;
  vaultConfig = lib.concatMapStrings
    (creds: ''
      template {
        destination = "${creds.path}"
        source = "${template creds}"
        perms = "0400"
        create_dest_dirs = false
        error_on_missing_key = ${error_on_missing_key creds}
        command = "${fixConfigFileOwner creds}"
      }
    ''
    )
    listOfCreds;

  mkdirsCmds = lib.concatMapStringsSep "\n"
    (creds: "${pkgs.coreutils}/bin/install -d -m 0700 -o ${creds.owner} -g ${creds.group} `${pkgs.coreutils}/bin/dirname ${creds.path}`")
    listOfCreds;

  tokens = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = name;
        example = "dhess";
        description = ''
          A short descriptive name for the Fly.io token.
        '';
      };

      vaultPath = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "secret/flyctl/dhess";
        description = ''
          The Vault KV2 secrets engine path for the Fly.io token.
        '';
      };

      path = lib.mkOption {
        type = pkgs.lib.types.nonStorePath;
        example = "/home/dhess/.fly/config.yml";
        description = ''
          The filesystem path where the flyctl config file containing
          the token will be persisted.

          By default, when a user runs <literal>flyctl</literal>, it
          looks for a config file in
          <literal>$HOME/.fly/config.yml</literal>, so that's a
          reasonable location for this file (though see the note below
          about specifying filesystem paths that include the user's
          home directory). However, Vault Agent will overwrite the
          contents of any existing file with this path, and the config
          file will contain only the access token, so if you have any
          custom flyctl config, you probably want to choose a
          different path for the Vault Agent-generated config file.

          Note that, unfortunately, Vault can't handle paths like
          <literal>~user</literal>, so if you want to set the value of
          the path to a path containing a particular user's home
          directory, you'll need to specify the literal pathname here.
        '';
      };

      owner = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "dhess";
        description = ''
          The filesystem owner of the flyctl config file that Vault
          Agent will persist to disk.
        '';
      };

      group = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "dhess";
        description = ''
          The filesystem group of the flyctl config file that Vault
          Agent will persist to disk.
        '';
      };

      exitOnMissingKey = lib.mkOption {
        type = pkgs.lib.types.bool;
        default = true;
        example = false;
        description = ''
          If true (the default), a failure to render the flyctl
          config will cause Vault Agent to exit with an error.
          This is a safeguard against silent failure. As this is
          extremely unlikely to occur in normal operation, you should
          probably keep the default value.
        '';
      };
    };
  };

in
{
  options.services.vault-agent.template.flyctl = lib.mkOption {
    type = pkgs.lib.types.attrsOf (pkgs.lib.types.submodule tokens);
    default = { };
    example = {
      dhess = {
        vaultPath = "secret/flyctl/dhess";
        path = "/home/dhess/.fly/config.yml";
        owner = "dhess";
        group = "dhess";
      };
    };
    description = ''
      Configure flyctl tokens (Fly.io).
    '';
  };

  config = lib.mkIf enabled {
    services.vault-agent.config = vaultConfig;
    services.vault-agent.preCommands = mkdirsCmds;
  };
}

