{ testingPython, ... }:
with testingPython;
let
  remoteBuilderKey = pkgs.writeText "remote-builder.key" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACB+blDZpS7Cb0ti9RZ4V+nQ2OSp2D4Xr/PHjtr7lDAeawAAAJCwjwJbsI8C
    WwAAAAtzc2gtZWQyNTUxOQAAACB+blDZpS7Cb0ti9RZ4V+nQ2OSp2D4Xr/PHjtr7lDAeaw
    AAAEAHLECnw3P1P/aASMGe/9iLItHCDMNInWfXnqlE1v11wH5uUNmlLsJvS2L1FnhX6dDY
    5KnYPhev88eO2vuUMB5rAAAACHNuYWtlb2lsAQIDBAU=
    -----END OPENSSH PRIVATE KEY-----
  '';
  remoteBuilderPublicKey = pkgs.writeText "remote-builder.pub"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5uUNmlLsJvS2L1FnhX6dDY5KnYPhev88eO2vuUMB5r alice";
  makeRemoteBuildHostTest = name: machineAttrs:
    makeTest {
      name = "remote-builder-test-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {
        server = { config, pkgs, ... }:
          {
            hacknix.remote-build-host = {
              enable = true;
              user.sshPublicKeyFiles =
                pkgs.lib.singleton remoteBuilderPublicKey;
            };
          } // machineAttrs;
        client = { config, pkgs, ... }: { };
      };

      testScript = { nodes, ... }:
        let
        in
        ''
          start_all()
          server.wait_for_unit("sshd.service")

          with subtest("SSH to remote builder"):
              client.succeed(
                  "cat ${remoteBuilderKey} > remote-builder.key"
              )
              client.succeed("chmod 0400 remote-builder.key")
              client.succeed(
                  "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i remote-builder.key -l remote-builder server true"
              )
        '';
    };
in
makeRemoteBuildHostTest "default" { }
