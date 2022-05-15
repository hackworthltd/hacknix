{ config
, pkgs
, lib
, inputs
, ...
}:
let
  cfg = config.services.vault-agent.template.netrc;
  enabled = cfg != { };

  netrcFile = app: "${app.dir}/netrc";

  templateContents = app: lib.concatMapStrings
    (creds: ''
      machine ${creds.hostname} login ${creds.login} password {{ with secret "${creds.vaultPath}" }}{{ .Data.data.token }}{{ end }}
    ''
    )
    (lib.mapAttrsToList (_: creds: creds) app.credentials);

  templateFile = app: pkgs.writeText "netrc.ctmpl" (templateContents app);

  fixNetrcFileOwner = app: pkgs.writeShellScript "fix-netrc-file-owner" ''
    ${pkgs.coreutils}/bin/chown ${app.owner}:${app.group} ${netrcFile app}
  '';

  create_dir = app: if app.createDir then "true" else "false";
  error_on_missing_key = app: if app.exitOnMissingKey then "true" else "false";

  listOfApps = lib.mapAttrsToList (_: apps: apps) cfg;

  vaultConfig = lib.concatMapStrings
    (app: ''
      template {
        destination = "${netrcFile app}"
        source = "${templateFile app}"
        perms = "0400"
        create_dest_dirs = ${create_dir app}
        error_on_missing_key = ${error_on_missing_key app}
        command = "${fixNetrcFileOwner app}"
      }
    ''
    )
    listOfApps;

  creds = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = name;
        example = "cachix";
        description = ''
          A short descriptive name for the credentials.
        '';
      };

      vaultPath = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "secret/cachix/hackworthltd";
        description = ''
          The Vault path for the password/token for these
          <literal>netrc</literal> credentials. Note that the
          password/token must be stored in a key/value pair whose key
          is named <literal>token</literal>.
        '';
      };

      login = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "alice";
        description = ''
          The login name for these credentials. Note that some clients
          may ignore this field, in which case you can use a nonce.
        '';
      };

      hostname = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "hackworthltd.cachix.org";
        description = ''
          The hostname of the machine for these credentials.
        '';
      };
    };
  };

  app = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = name;
        example = "nix";
        description = ''
          A short descriptive name for the application. This permits
          per-app <literal>netrc</literal> files.
        '';
      };

      dir = lib.mkOption {
        type = pkgs.lib.types.nonStorePath;
        example = "/etc/nix";
        description = ''
          The directory where the <literal>netrc</literal>
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
        '';
      };

      owner = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "root";
        description = ''
          The filesystem owner of the <literal>netrc</literal> config
          file that Vault Agent will persist to disk.
        '';
      };

      group = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "dhess";
        description = ''
          The filesystem group of the <literal>netrc</literal> config
          file that Vault Agent will persist to disk.
        '';
      };

      exitOnMissingKey = lib.mkOption {
        type = pkgs.lib.types.bool;
        default = true;
        example = false;
        description = ''
          If true (the default), a failure to render the
          <literal>netrc</literal> file will cause Vault Agent to exit
          with an error. This is a safeguard against silent failure.
          As this is extremely unlikely to occur in normal operation,
          you should probably keep the default value.
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
  options.services.vault-agent.template.netrc = lib.mkOption {
    type = pkgs.lib.types.attrsOf (pkgs.lib.types.submodule app);
    default = { };
    example = {
      nix = {
        dir = "/etc/nix";
        owner = "root";
        group = "wheel";
        credentials = {
          cachix = {
            vaultPath = "secret/cachix/hackworthltd";
            hostname = "hackworthltd.cachix.org";
          };
        };
      };
    };
    description = ''
      Configure per-app netrc credentials using Vault.
    '';
  };

  config = lib.mkIf enabled {
    services.vault-agent.config = vaultConfig;
  };
}


