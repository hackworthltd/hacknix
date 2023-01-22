args:

args // {
  system = "x86_64-linux";
  modules = [
    ({ pkgs, ... }:
      let
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBp7K+EqL+5Ry40pQrHRDd9H/jh/eaYYYV0uxH9cxa0q";
      in
      {
        networking.hostName = "build-host";
        system.stateVersion = "23.05";
        hacknix.defaults.enable = true;
        hacknix.build-host.enable = true;
        hacknix.build-host.buildMachines = {
          remote-builder = {
            hostName = "remote-builder.example.com";
            alternateHostNames = [ "192.0.2.1" "2001:db8::1" ];
            hostPublicKeyLiteral = sshPublicKey;
            systems = [ "x86_64-linux" "i686-linux" ];
            maxJobs = 4;
            speedFactor = 1;
            supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
            sshUserName = "remote-builder";
          };
        };
        users.users.root.openssh.authorizedKeys.keys = [
          sshPublicKey
        ];

        services.vault-agent = {
          enable = true;
          server.address = "http://example.com";
        };
        services.vault-agent.auth.approle = {
          enable = true;
          roleIdPath = "/var/lib/vault-agent/roleid";
          secretIdPath = "/var/lib/vault-agent/secretid";
        };
        services.vault-agent.templates.nix-access-tokens = {
          destination = "/etc/nix/access-tokens";
          template = ''
            access-tokens = github.com={{ with secret "github/token/repos" }}{{ .Data.token }}{{ end }}
          '';
          command = ''
            chmod dhess:dhess /home/dhess/.config/nix.conf
          '';
          createDir = {
            owner = "dhess";
            group = "dhess";
          };
        };
        services.vault-agent.template.aws-credentials.binary-cache = {
          vaultPath = "aws/sts/nix-binary-cache";
          dir = "/root/.aws";
          owner = "root";
          group = "root";
        };
        services.vault-agent.template.cachix.hackworthltd = {
          vaultPath = "secret/cachix/hackworthltd/write";
          dir = "/home/dhess/.config/cachix";
          owner = "dhess";
          group = "dhess";
        };
        services.vault-agent.template.github-credentials.dhess = {
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
        services.vault-agent.template.netrc.nix = {
          dir = "/etc/nix";
          owner = "root";
          group = "wheel";
          credentials = {
            hackworthltd = {
              vaultPath = "secret/cachix/hackworthltd";
              login = "dhess";
              hostname = "hackworthltd.cachix.org";
            };
          };
        };
        services.vault-agent.template.flyctl.dhess = {
          vaultPath = "secret/flyctl/dhess";
          path = "/home/dhess/.fly/config.yml";
          owner = "dhess";
          group = "dhess";
        };
      })
  ];
}
