{ lib
, ...
}:
{
  system = "aarch64-darwin";
  modules = lib.singleton
    ({ pkgs, ... }: {
      # For now, setting this is required.
      environment.darwinConfig = "${pkgs.lib.hacknix.path}/examples/nix-darwin/build-host.nix";

      system.stateVersion = 5;

      nix.settings.max-jobs = 16;

      hacknix-nix-darwin.build-host = {
        enable = true;
        createSshKey = false;
        buildMachines = {
          remote-builder = {
            hostName = "remote-builder.example.com";
            alternateHostNames = [ "192.0.2.1" "2001:db8::1" ];
            hostPublicKeyLiteral =
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBp7K+EqL+5Ry40pQrHRDd9H/jh/eaYYYV0uxH9cxa0q";
            systems = [ "x86_64-linux" "i686-linux" ];
            maxJobs = 4;
            speedFactor = 1;
            supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
            sshUserName = "remote-builder";
          };

          # A build machine with no associated public key. This might
          # be useful when using an SSH CA for host keys.
          remote-builder-no-hostkey = {
            hostName = "remote-builder-no-hostkey.example.com";
            alternateHostNames = [ "192.0.2.2" "2001:db8::2" ];
            systems = [ "x86_64-linux" "i686-linux" ];
            maxJobs = 4;
            speedFactor = 1;
            supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
            sshUserName = "remote-builder";
          };
        };
      };

      # Use Vault to issue SSH CA-signed keys for the remote builder.
      services.vault-agent.template.remote-builder-ssh.enable = true;

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
          ${pkgs.coreutils}/bin/chmod dhess:admin /Users/dhess/.config/nix.conf
        '';
        createDir = {
          owner = "dhess";
          group = "admin";
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
        group = "admin";
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
    });
}
