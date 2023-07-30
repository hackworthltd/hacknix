{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.services.vault-agent.template.remote-builder-ssh;
  permissions = "0400";

  privateKeyFileName = "remote-builder";
  publicKeyFileName = "${privateKeyFileName}.pub";

  # Vault Agent can't write multiple files from a single secret, so we
  # need to do this convoluted thing.
  #
  # The split-key script may have a race on some platforms, where the
  # public and private keys may not be written atomically. Fixing this
  # in a cross-platform way is tricky, so we leave it as is for now;
  # let's see how often it causes problems.

  template = pkgs.writeText "remote-builder.json.ctmpl" ''
    {{ with secret "${cfg.vaultIssuePath}" "key_type=ed25519" }}
    {
      "private_key": {{ .Data.private_key | toJSON }},
      "public_key": {{ .Data.signed_key | toJSON }}
    }
    {{ end }}
  '';

  splitKey = pkgs.writeShellApplication {
    name = "split-key";
    runtimeInputs = with pkgs; [
      jq
      coreutils
    ];
    text = ''
      chown ${cfg.user}:${cfg.group} ${cfg.jsonFile}

      TEMPDIR=$(mktemp -d)
      trap 'rm -rf $TEMPDIR' EXIT
      cd "$TEMPDIR"

      jq -r '.private_key' ${cfg.jsonFile} > ${privateKeyFileName}
      jq -r '.public_key' ${cfg.jsonFile} > ${publicKeyFileName}

      chown ${cfg.user}:${cfg.group} ${privateKeyFileName}
      chown ${cfg.user}:${cfg.group} ${publicKeyFileName}
      chmod ${permissions} ${privateKeyFileName}
      chmod 0644 ${publicKeyFileName}

      mv "$TEMPDIR"/* ${cfg.keyDir}
    '';
  };

  error_on_missing_key = if cfg.exitOnMissingKey then "true" else "false";
in
{
  options.services.vault-agent.template.remote-builder-ssh = {
    enable = lib.mkEnableOption "Enable the remote builder SSH template.";

    vaultIssuePath = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "ssh/issue/remote-builder-user";
      description = ''
        The path to the Vault SSH secrets engine role for issuing
        signed SSH keys. The role should allow username
        <literal>remote-builder</literal> and should support the
        generation of <literal>ed25519</literal> keys.
      '';
    };

    keyDir = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      default = "/var/lib/remote-build-keys";
      description = ''
        The directory where Vault Agent will write the remote-builder
        SSH secrets.
      '';
    };

    user = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "admin";
      default = "root";
      description = ''
        The local user who owns the key files.
      '';
    };

    group = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "admin";
      default = if pkgs.stdenv.isDarwin then "wheel" else "root";
      description = ''
        The group which owns the key files.
      '';
    };

    exitOnMissingKey = lib.mkOption {
      type = pkgs.lib.types.bool;
      default = false;
      example = true;
      description = ''
        If true, a failure to render the private key will
        cause Vault Agent to exit with an error.
      '';
    };

    jsonFile = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      readOnly = true;
      default = "${cfg.keyDir}/remote-builder.json";
      description = ''
        The path to the JSON file containing secrets from Vault.
      '';
    };

    privateKeyFile = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      readOnly = true;
      default = "${cfg.keyDir}/${privateKeyFileName}";
      description = ''
        The path to the private key file. This file has permissions
        0400.
      '';
    };

    publicKeyFile = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      readOnly = true;
      default = "${cfg.keyDir}/${publicKeyFileName}";
      description = ''
        The path to the public key file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.vault-agent.config = ''
      template {
        destination = "${cfg.privateKeyFile}.json"
        source = "${template}"
        perms = "${permissions}"
        create_dest_dirs = true
        error_on_missing_key = ${error_on_missing_key}
        command = "${splitKey}/bin/split-key"
      }
    '';
  };
}

