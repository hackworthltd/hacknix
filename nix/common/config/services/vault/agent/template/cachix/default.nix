{ config
, pkgs
, lib
, inputs
, ...
}:
let
  cfg = config.services.vault-agent.template.cachix;
  enabled = cfg != { };

  cachixFile = creds: "${creds.dir}/cachix.dhall";

  template = creds: pkgs.writeText "cachix.dhall.ctmpl" ''
    { authToken = {{ with secret "${creds.vaultPath}" }}"{{ .Data.data.token }}"{{ end }}, binaryCaches = [] : List { name : Text, secretKey : Text }
    }
  '';

  fixCachixFileOwner = creds: pkgs.writeShellScript "fix-cachix-file-owner" ''
    ${pkgs.coreutils}/bin/chown ${creds.owner}:${creds.group} ${cachixFile creds}
  '';

  error_on_missing_key = creds: if creds.exitOnMissingKey then "true" else "false";

  listOfCreds = lib.mapAttrsToList (_: creds: creds) cfg;
  vaultConfig = lib.concatMapStrings
    (creds: ''
      template {
        destination = "${cachixFile creds}"
        source = "${template creds}"
        perms = "0400"
        create_dest_dirs = false
        error_on_missing_key = ${error_on_missing_key creds}
        command = "${fixCachixFileOwner creds}"
      }
    ''
    )
    listOfCreds;

  mkdirsCmds = lib.concatMapStringsSep "\n"
    (creds: "${pkgs.coreutils}/bin/install -d -m 0700 -o ${creds.owner} -g ${creds.group} ${creds.dir}")
    listOfCreds;

  tokens = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = name;
        example = "hackworthltd";
        description = ''
          A short descriptive name for the token.
        '';
      };

      vaultPath = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "secret/cachix/hackworthltd/write";
        description = ''
          The Vault KV2 secrets engine path for the Cachix token.
        '';
      };

      dir = lib.mkOption {
        type = pkgs.lib.types.nonStorePath;
        example = "/home/dhess/.config/cachix";
        description = ''
          The directory where the Cachix config will be persisted. In
          this directory, this module will persist the Cachix config
          in a file whose name is <literal>cachix.dhall</literal>.

          Note that, unfortunately, Vault can't handle paths like
          <literal>~user</literal>, so if you want to set this to a
          particular user's home directory, you'll need to specify the
          literal pathname here.
        '';
      };

      owner = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "dhess";
        description = ''
          The filesystem owner of the Cachix config file that Vault
          Agent will persist to disk.
        '';
      };

      group = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "dhess";
        description = ''
          The filesystem group of the Cachix config file that Vault
          Agent will persist to disk.
        '';
      };

      exitOnMissingKey = lib.mkOption {
        type = pkgs.lib.types.bool;
        default = true;
        example = false;
        description = ''
          If true (the default), a failure to render the Cachix
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
  options.services.vault-agent.template.cachix = lib.mkOption {
    type = pkgs.lib.types.attrsOf (pkgs.lib.types.submodule tokens);
    default = { };
    example = {
      hackworthltd = {
        vaultPath = "secret/cachix/hackworthltd/write";
        dir = "/home/dhess/.config/cachix";
        owner = "dhess";
        group = "dhess";
      };
    };
    description = "Configure Cachix tokens.";
  };

  config = lib.mkIf enabled {
    services.vault-agent.config = vaultConfig;
    services.vault-agent.preCommands = mkdirsCmds;
  };
}

