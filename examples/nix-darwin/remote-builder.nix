{ lib
, ...
}:
{
  system = "aarch64-darwin";
  modules = lib.singleton
    ({ pkgs, config, ... }:
      let
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkRyutu3OMvSDFQOsOtls4A5krFlYEPbiPG/qUyxGdb example remote-builder key";
      in
      {
        # For now, setting this is required.
        environment.darwinConfig = "${pkgs.lib.hacknix.path}/examples/nix-darwin/remote-builder.nix";

        nix.settings.max-jobs = 12;

        hacknix-nix-darwin.remote-build-host = {
          enable = true;
          user.sshPublicKeys = lib.singleton sshPublicKey;
        };

        services.vault-agent = {
          enable = true;
          server.address = "http://example.com";
        };
        services.vault-agent.auth.approle = {
          enable = true;
          roleIdPath = "/var/lib/vault-agent/roleid";
          secretIdPath = "/var/lib/vault-agent/secretid";
        };
        services.vault-agent.template.ssh-ca-host-key = {
          enable = true;
          vaultIssuePath = "ssh-host/issue/internal";
          hostnames = [
            "remote-builder.example.com"
          ];
        };

        environment.etc = {
          "ssh/sshd_config.d/999-ssh-ca-host-keys.conf" = {
            text = ''
              HostKey ${config.services.vault-agent.template.ssh-ca-host-key.privateKeyFile}
              HostCertificate ${config.services.vault-agent.template.ssh-ca-host-key.publicKeyFile}
            '';
          };
        };
      });
}

