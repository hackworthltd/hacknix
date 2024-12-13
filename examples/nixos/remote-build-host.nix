args:
args
// {
  system = "x86_64-linux";
  modules = [
    (
      { pkgs, config, ... }:
      let
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBp7K+EqL+5Ry40pQrHRDd9H/jh/eaYYYV0uxH9cxa0q";
      in
      {
        networking.hostName = "remote-builder";
        system.stateVersion = "23.05";
        hacknix.defaults.enable = true;
        hacknix.remote-build-host.enable = true;
        hacknix.remote-build-host.user.sshPublicKeys = [ sshPublicKey ];
        users.users.root.openssh.authorizedKeys.keys = [ sshPublicKey ];

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

        services.openssh.extraConfig = ''
          HostKey ${config.services.vault-agent.template.ssh-ca-host-key.privateKeyFile}
          HostCertificate ${config.services.vault-agent.template.ssh-ca-host-key.publicKeyFile}
        '';
      }
    )
  ];
}
