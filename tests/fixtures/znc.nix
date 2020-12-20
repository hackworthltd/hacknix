{ testingPython, ... }:
with testingPython;
let
  imports = [ ../include/deploy-keys.nix ];

  makeZncTest = name:
    makeTest {
      name = "znc-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {
        localhostServer = { pkgs, config, ... }: {
          inherit imports;

          # Use the test key deployment system.
          deployment.reallyReallyEnable = true;

          services.qx-znc = {
            enable = true;
            mutable = false;
            openFirewall = true;
            configLiteral = pkgs.lib.hacknix.mkZncConfig {
              inherit pkgs;
              zncServiceConfig = config.services.qx-znc;
            };
            confOptions = {
              host = "localhost";
              userName = "bob-znc";
              nick = "bob";
              passBlock =
                "\n                <Pass password>\n                  Method = sha256\n                  Hash = e2ce303c7ea75c571d80d8540a8699b46535be6a085be3414947d638e48d9e93\n                  Salt = l5Xryew4g*!oa(ECfX2o\n                </Pass>\n              ";
            };
          };
        };

        server = { pkgs, config, ... }: {
          inherit imports;

          # Use the test key deployment system.
          deployment.reallyReallyEnable = true;

          services.qx-znc = {
            enable = true;
            mutable = false;
            openFirewall = true;
            configLiteral = pkgs.lib.hacknix.mkZncConfig {
              inherit pkgs;
              zncServiceConfig = config.services.qx-znc;
            };
            confOptions = {
              userName = "bob-znc";
              nick = "bob";
              passBlock =
                "\n                <Pass password>\n                  Method = sha256\n                  Hash = e2ce303c7ea75c571d80d8540a8699b46535be6a085be3414947d638e48d9e93\n                  Salt = l5Xryew4g*!oa(ECfX2o\n                </Pass>\n              ";
            };
          };
        };

        client = { pkgs, config, ... }: { };

      };

      testScript = { nodes, ... }: ''
        start_all()

        server.wait_for_unit("znc.service")
        localhostServer.wait_for_unit("znc.service")

        with subtest("No remote connections"):
            client.fail(
                "${nodes.client.pkgs.netcat}/bin/nc -w 5 localhostServer ${builtins.toString nodes.localhostServer.config.services.qx-znc.confOptions.port}"
            )

        with subtest("Localhost connections"):
            localhostServer.succeed(
                "${pkgs.netcat}/bin/nc -w 5 localhost ${builtins.toString nodes.localhostServer.config.services.qx-znc.confOptions.port}"
            )

        with subtest("Allow remote connections"):
            client.succeed(
                "${pkgs.netcat}/bin/nc -w 5 server ${builtins.toString nodes.server.config.services.qx-znc.confOptions.port}"
            )
      '';

    };
in
{
  defaultTest = makeZncTest "default";
}
