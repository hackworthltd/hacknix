{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.services.vault-agent.template.ssh-ca-host-key;
  permissions = "0400";

  privateKeyFileName = "ssh_ca_host_ed25519_key";
  publicKeyFileName = "${privateKeyFileName}.pub";

  valid_principals = lib.concatStringsSep "," cfg.hostnames;

  # Vault Agent can't write multiple files from a single secret, so we
  # need to do this convoluted thing.
  #
  # The split-key script may have a race on some platforms, where the
  # public and private keys may not be written atomically. Fixing this
  # in a cross-platform way is tricky, so we leave it as is for now;
  # let's see how often it causes problems.

  template = pkgs.writeText "ssh_ca_host_ed25519_key.json.ctmpl" ''
    {{ with secret "${cfg.vaultIssuePath}" "key_type=ed25519" "cert_type=host" "valid_principals=${valid_principals}" }}
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
  options.services.vault-agent.template.ssh-ca-host-key = {
    enable = lib.mkEnableOption ''
      create an SSH host key from a Vault SSH CA.

      Note that this service does not modify the
      <literal>sshd</literal> config to use the key. That
      configuration must be done separately.
    '';

    vaultIssuePath = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "ssh-host/issue/internal";
      description = ''
        The path to the Vault SSH secrets engine role for issuing
        signed SSH host keys.
      '';
    };

    hostnames = lib.mkOption {
      type = pkgs.lib.types.nonEmptyListOf pkgs.lib.types.nonEmptyStr;
      example = [
        "localhost"
        "foo.example.com"
      ];
      description = ''
        The hostnames for which the SSH host key is valid.
      '';
    };

    keyDir = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      default = "/etc/ssh";
      description = ''
        The directory where Vault Agent will write the SSH host key
        and certificate.
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
      default = "${cfg.keyDir}/ssh_ca_host_ed25519_key.json";
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

  config = (lib.mkIf cfg.enable {
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
  }) // (lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    services.openssh.extraConfig = ''
      HostKey ${cfg.privateKeyFile}
      HostCertificate ${cfg.publicKeyFile}
    '';
  }) // (lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    environment.etc = {
      "ssh/sshd_config.d/999-ssh-ca-host-keys.conf" = {
        text = ''
          HostKey ${cfg.privateKeyFile}
          HostCertificate ${cfg.publicKeyFile}
        '';
      };
    };
  });
}

