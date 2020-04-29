{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
  alicePrivateKey = pkgs.writeText "alice.key" ''
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

  bobPrivateKey = pkgs.writeText "bob.key" ''
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

  rootPrivateKey = pkgs.writeText "root.key" ''
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

  makeSshTest = name: machineAttrs:
    makeTest {
      name = "ssh-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

      nodes = {
        server = { config, ... }:
          {
            nixpkgs.localSystem.system = system;
            imports = [ ./common/users.nix ./common/root-user.nix ]
            ++ pkgs.lib.hacknix.modules;
            users.users.root.openssh.authorizedKeys.keys = [ rootPublicKey ];
            users.users.alice.openssh.authorizedKeys.keys = [ alicePublicKey ];
            users.users.bob.openssh.authorizedKeys.keys = [ bobPublicKey ];
          } // machineAttrs;
        badserver = { config, ... }: {
          nixpkgs.localSystem.system = system;
          imports = [ ./common/users.nix ./common/root-user.nix ];
          users.users.root.openssh.authorizedKeys.keys = [ rootPublicKey ];
          users.users.alice.openssh.authorizedKeys.keys = [ alicePublicKey ];
          users.users.bob.openssh.authorizedKeys.keys = [ bobPublicKey ];
          services.openssh.enable = true;
          services.openssh.passwordAuthentication = true;
          services.openssh.permitRootLogin = "yes";
        };
        client = { config, ... }: {
          nixpkgs.localSystem.system = system;
          imports = pkgs.lib.hacknix.modules;
        };
      };

      testScript = { nodes, ... }:
        let
          alice = nodes.server.config.users.users.alice;
          bob = nodes.server.config.users.users.bob;
          root = nodes.server.config.users.users.root;
        in ''
          startAll;
          $server->waitForUnit("sshd.service");

          subtest "user-authkey", sub {
            $client->succeed("cat ${alicePrivateKey} > alice.key");
            $client->succeed("chmod 0600 alice.key");
            $client->succeed("ssh -o UserKnownHostsFile=/dev/null" .
                             " -o StrictHostKeyChecking=no -i alice.key" .
                             " -l alice server true");

            $client->succeed("cat ${bobPrivateKey} > bob.key");
            $client->succeed("chmod 0600 bob.key");
            $client->succeed("ssh -o UserKnownHostsFile=/dev/null" .
                             " -o StrictHostKeyChecking=no -i bob.key" .
                             " -l bob server true");
          };

          subtest "root-authkey", sub {
            $client->succeed("cat ${rootPrivateKey} > root.key");
            $client->succeed("chmod 0600 root.key");
            $client->succeed("ssh -o UserKnownHostsFile=/dev/null" .
                             " -o StrictHostKeyChecking=no -i root.key" .
                             " -l root server true");
          };

          subtest "user-password-disallowed", sub {
            my $sshcmd = "${pkgs.sshpass}/bin/sshpass -p ${alice.password}" .
                         " ssh -o UserKnownHostsFile=/dev/null" .
                         " -o StrictHostKeyChecking=no -l alice";
            $client->fail($sshcmd . " server true") =~ /Permission denied (publickey,keyboard-interactive)/;

            # Make sure the same command succeeds on the misconfigured server.
            $client->succeed($sshcmd . " badserver true");
          };

          subtest "root-password-disallowed", sub {
            my $sshcmd = "${pkgs.sshpass}/bin/sshpass -p ${root.password}" .
                         " ssh -o UserKnownHostsFile=/dev/null" .
                         " -o StrictHostKeyChecking=no -l root";
            $client->fail($sshcmd . " server true") =~ /Permission denied (publickey,keyboard-interactive)/;

            # Make sure the same command succeeds on the misconfigured server.
            $client->succeed($sshcmd . " badserver true");
          };

        '';
    };
in
rec {

  globalEnableTest =
    makeSshTest "global-enable" { hacknix.defaults.enable = true; };
  sshEnableTest =
    makeSshTest "ssh-enable" { hacknix.defaults.ssh.enable = true; };

}
