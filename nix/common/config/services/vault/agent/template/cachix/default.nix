{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.services.vault-agent.template.cachix;
  enabled = cfg != { };

  cachixFile = creds: "${creds.dir}/cachix-${creds.name}";

  template =
    creds:
    pkgs.writeText "cachix.ctmpl" ''
      {{ with secret "${creds.vaultPath}" }}{{ .Data.data.token }}{{ end }}
    '';

  fixCachixFileOwner =
    creds:
    pkgs.writeShellScript "fix-cachix-file-owner" ''
      ${pkgs.coreutils}/bin/chown ${creds.owner}:${creds.group} ${cachixFile creds}
    '';

  error_on_missing_key = creds: if creds.exitOnMissingKey then "true" else "false";

  listOfCreds = lib.mapAttrsToList (_: creds: creds) cfg;
  vaultConfig = lib.concatMapStrings (creds: ''
    template {
      destination = "${cachixFile creds}"
      source = "${template creds}"
      perms = "0440"
      create_dest_dirs = false
      error_on_missing_key = ${error_on_missing_key creds}
      command = "${fixCachixFileOwner creds}"
    }
  '') listOfCreds;

  mkdirsCmds = lib.concatMapStringsSep "\n" (
    creds: "${pkgs.coreutils}/bin/install -d -m 0750 -o ${creds.owner} -g ${creds.group} ${creds.dir}"
  ) listOfCreds;

  tokens =
    { name, ... }:
    {
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
            The directory where the Cachix token will be persisted.
          '';
        };

        owner = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "dhess";
          description = ''
            The filesystem owner of the Cachix token file that Vault
            Agent will persist to disk.
          '';
        };

        group = lib.mkOption {
          type = pkgs.lib.types.nonEmptyStr;
          example = "dhess";
          description = ''
            The filesystem group of the Cachix token file that Vault
            Agent will persist to disk.
          '';
        };

        exitOnMissingKey = lib.mkOption {
          type = pkgs.lib.types.bool;
          default = true;
          example = false;
          description = ''
            If true (the default), a failure to render the Cachix
            token will cause Vault Agent to exit with an error.
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
