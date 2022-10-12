{ hostPkgs, ... }:
let
  alicePrivateKey = hostPkgs.writeText "alice.key" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACB+blDZpS7Cb0ti9RZ4V+nQ2OSp2D4Xr/PHjtr7lDAeawAAAJCwjwJbsI8C
    WwAAAAtzc2gtZWQyNTUxOQAAACB+blDZpS7Cb0ti9RZ4V+nQ2OSp2D4Xr/PHjtr7lDAeaw
    AAAEAHLECnw3P1P/aASMGe/9iLItHCDMNInWfXnqlE1v11wH5uUNmlLsJvS2L1FnhX6dDY
    5KnYPhev88eO2vuUMB5rAAAACHNuYWtlb2lsAQIDBAU=
    -----END OPENSSH PRIVATE KEY-----
  '';
  alicePublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5uUNmlLsJvS2L1FnhX6dDY5KnYPhev88eO2vuUMB5r alice";
  bobPrivateKey = hostPkgs.writeText "bob.key" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACAk3+h091DYdMygZn4/yQVfxL3AVPIMr7REdD6kPhWdfwAAAIgIfUUECH1F
    BAAAAAtzc2gtZWQyNTUxOQAAACAk3+h091DYdMygZn4/yQVfxL3AVPIMr7REdD6kPhWdfw
    AAAEDk8pnmUq92l0Gto2mILITMfH6eWhiVUZbtqLc4gb7ViiTf6HT3UNh0zKBmfj/JBV/E
    vcBU8gyvtER0PqQ+FZ1/AAAAA2JvYgEC
    -----END OPENSSH PRIVATE KEY-----
  '';
  bobPublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICTf6HT3UNh0zKBmfj/JBV/EvcBU8gyvtER0PqQ+FZ1/ bob";
  rootPrivateKey = hostPkgs.writeText "root.key" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACD56cAoUUa7vCw5aQ7jXgUfUvnFM1PKOiSVYKkCds2eBQAAAIhcJUFJXCVB
    SQAAAAtzc2gtZWQyNTUxOQAAACD56cAoUUa7vCw5aQ7jXgUfUvnFM1PKOiSVYKkCds2eBQ
    AAAEDaSWk3nv0e5gUeS+geYYTSdbz/tyOyFVHPmsMDHtdxVvnpwChRRru8LDlpDuNeBR9S
    +cUzU8o6JJVgqQJ2zZ4FAAAABHJvb3QB
    -----END OPENSSH PRIVATE KEY-----
  '';
  rootPublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnpwChRRru8LDlpDuNeBR9S+cUzU8o6JJVgqQJ2zZ4F root";
in
{
  meta = with hostPkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes =
    let
      imports = [ ../include/users.nix ../include/root-user.nix ];
    in
    {
      server1 = { pkgs, config, ... }:
        {
          inherit imports;
          hacknix.defaults.enable = true;
          users.users.root.openssh.authorizedKeys.keys = [ rootPublicKey ];
          users.users.alice.openssh.authorizedKeys.keys = [ alicePublicKey ];
          users.users.bob.openssh.authorizedKeys.keys = [ bobPublicKey ];
        };
      server2 = { pkgs, config, ... }:
        {
          inherit imports;
          hacknix.defaults.ssh.enable = true;
          users.users.root.openssh.authorizedKeys.keys = [ rootPublicKey ];
          users.users.alice.openssh.authorizedKeys.keys = [ alicePublicKey ];
          users.users.bob.openssh.authorizedKeys.keys = [ bobPublicKey ];
        };
      client = { pkgs, config, ... }: {
        inherit imports;
        environment.systemPackages = with pkgs; [ sshpass ];
      };
    };

  testScript = { nodes, ... }:
    let
      alice = nodes.server1.users.users.alice;
      bob = nodes.server1.users.users.bob;
      root = nodes.server1.users.users.root;
    in
    ''
      start_all()
      server1.wait_for_unit("sshd.service")
      server2.wait_for_unit("sshd.service")

      with subtest("User authkey"):
          client.succeed(
              "cat ${alicePrivateKey} > alice.key"
          )
          client.succeed("chmod 0600 alice.key")
          client.succeed(
              "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i alice.key -l alice server1 true"
          )
          client.succeed(
              "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i alice.key -l alice server2 true"
          )

          client.succeed("cat ${bobPrivateKey} > bob.key")
          client.succeed("chmod 0600 bob.key")
          client.succeed(
              "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i bob.key -l bob server1 true"
          )
          client.succeed(
              "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i bob.key -l bob server2 true"
          )

      with subtest("root authkey"):
          client.succeed(
              "cat ${rootPrivateKey} > root.key"
          )
          client.succeed("chmod 0600 root.key")
          client.succeed(
              "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i root.key -l root server1 true"
          )
          client.succeed(
              "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i root.key -l root server2 true"
          )
          
      with subtest("Disallow user password"):
          sshcmd = "sshpass -p ${alice.password} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l alice"
          client.fail(sshcmd + " server1 true")
          client.fail(sshcmd + " server2 true")
          
      with subtest("Disallow root password"):
          sshcmd = "sshpass -p ${root.password} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l root"
          client.fail(sshcmd + " server1 true")
          client.fail(sshcmd + " server2 true")
    '';
}
