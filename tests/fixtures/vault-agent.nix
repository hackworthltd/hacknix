{ testingPython, ... }:
with testingPython;
let
in
makeTest rec {
  name = "vault-agent";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    server = { pkgs, config, ... }: {
      networking.firewall.allowedTCPPorts = [ 8200 ];
    };

    agent = { pkgs, config, ... }: {
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
    };
  };

  testScript = { nodes, ... }: ''
    start_all()

    server.wait_for_unit("multi-user.target")
    server.succeed(
        "${nodes.server.pkgs.vault}/bin/vault server -dev -dev-listen-address='[::]:8200' -dev-root-token-id=root &"
    )

    agent.wait_for_unit("vault-agent.service")
    agent.wait_for_unit("multi-user.target")

    agent.wait_until_succeeds(
        "${nodes.agent.pkgs.netcat}/bin/nc -z server 8200"
    )
    agent.succeed(
        "VAULT_AGENT_ADDR=http://127.0.0.1:8200 ${nodes.agent.pkgs.vault}/bin/vault status"
    )
  '';
}
