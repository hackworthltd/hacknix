{ hostPkgs, ... }:
{
  meta = with hostPkgs.lib.maintainers; {
    maintainers = [ dhess ];
  };

  nodes = {
    server =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        nixpkgs.config.allowUnfree = true;
        networking.firewall.allowedTCPPorts = [ 8200 ];
        services.vault = {
          enable = true;
        };
        systemd.services.vault.serviceConfig.ExecStart =
          lib.mkForce "${config.services.vault.package}/bin/vault server -dev -dev-listen-address='[::]:8200' -dev-root-token-id=root -dev-no-store-token=true";
      };

    agent =
      { pkgs, config, ... }:
      {
        nixpkgs.config.allowUnfree = true;
        services.vault-agent = {
          enable = true;
          server.address = "http://server:8200";
          config = ''
            cache {
              use_auto_auth_token = false
            }
            listener "tcp" {
              address = "127.0.0.1:8200"
              tls_disable = true
            }
          '';
        };

        environment.systemPackages = with pkgs; [
          netcat
          vault
        ];
      };
  };

  testScript =
    { nodes, ... }:
    ''
      start_all()

      server.wait_for_unit("vault.service")

      agent.wait_for_unit("vault-agent.service")
      agent.wait_for_unit("multi-user.target")

      agent.wait_until_succeeds(
          "nc -z server 8200",
          timeout=10
      )
      agent.succeed(
          "VAULT_AGENT_ADDR=http://127.0.0.1:8200 vault status"
      )
    '';
}
