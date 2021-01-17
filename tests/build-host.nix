# Note: this test doesn't perform any remote builds; it merely ensures
# that the files and keys needed to support remote builds are set up
# correctly.

{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  expectedMachinesFile = pkgs.writeText "machines" ''
    ssh://bob@bar.example.com x86_64-linux,i686-linux /etc/nix/bob_at_bar 16 2 benchmark,big-parallel,kvm,nixos-test benchmark
    ssh://alice@foo.example.com x86_64-darwin /etc/nix/alice_at_foo 4 1 big-parallel
    ssh://syd@qux.example.com x86_64-linux,i686-linux /etc/nix/remote-builder 8 1 big-parallel,kvm,nixos-test
  '';
  expectedExtraMachinesFile = pkgs.writeText "extra-machines" ''
    ssh://alice@baz.example.com aarch64-linux /etc/nix/alice_at_baz 6 2 big-parallel,nixos-test
  '';
  alicePrivateKey = ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACB+blDZpS7Cb0ti9RZ4V+nQ2OSp2D4Xr/PHjtr7lDAeawAAAJCwjwJbsI8C
    WwAAAAtzc2gtZWQyNTUxOQAAACB+blDZpS7Cb0ti9RZ4V+nQ2OSp2D4Xr/PHjtr7lDAeaw
    AAAEAHLECnw3P1P/aASMGe/9iLItHCDMNInWfXnqlE1v11wH5uUNmlLsJvS2L1FnhX6dDY
    5KnYPhev88eO2vuUMB5rAAAACHNuYWtlb2lsAQIDBAU=
    -----END OPENSSH PRIVATE KEY-----
  '';
  alicePrivateKeyFile = pkgs.writeText "alice.key" alicePrivateKey;
  alicePublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5uUNmlLsJvS2L1FnhX6dDY5KnYPhev88eO2vuUMB5r alice";
  bobPrivateKey = ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACAk3+h091DYdMygZn4/yQVfxL3AVPIMr7REdD6kPhWdfwAAAIgIfUUECH1F
    BAAAAAtzc2gtZWQyNTUxOQAAACAk3+h091DYdMygZn4/yQVfxL3AVPIMr7REdD6kPhWdfw
    AAAEDk8pnmUq92l0Gto2mILITMfH6eWhiVUZbtqLc4gb7ViiTf6HT3UNh0zKBmfj/JBV/E
    vcBU8gyvtER0PqQ+FZ1/AAAAA2JvYgEC
    -----END OPENSSH PRIVATE KEY-----
  '';
  bobPrivateKeyFile = pkgs.writeText "bob.key" bobPrivateKey;
  bobPublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICTf6HT3UNh0zKBmfj/JBV/EvcBU8gyvtER0PqQ+FZ1/ bob";
  fooPublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsvvICWc8HDQkkIwIaHQ2xuHieJyLULqe1Z/xeJQRzi";
  barPublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAEBze0BfSijN9vRgvLOyJacAo7rCgr9u96hGWNkyPL";
  bazPublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
  quxPublicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFUD3f/kxQgu+DJHjy/3jWqqTZk6rnWrwBabt+WTBWfT";
  remoteBuildHosts = {
    foo = {
      hostName = "foo.example.com";
      alternateHostNames = [ "10.0.0.1" "2001:db8::1" ];
      hostPublicKeyLiteral = fooPublicKey;
      systems = [ "x86_64-darwin" ];
      maxJobs = 4;
      speedFactor = 1;
      supportedFeatures = [ "big-parallel" ];
      sshUserName = "alice";
      sshKeyLiteral = alicePrivateKey;
    };
    bar = {
      hostName = "bar.example.com";
      port = 2002;
      alternateHostNames = [ "10.0.0.2" "2001:db8::2" ];
      hostPublicKeyLiteral = barPublicKey;
      systems = [ "x86_64-linux" "i686-linux" ];
      maxJobs = 16;
      speedFactor = 2;
      mandatoryFeatures = [ "benchmark" ];
      supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
      sshUserName = "bob";
      sshKeyLiteral = bobPrivateKey;
    };
    qux = {
      hostName = "qux.example.com";
      alternateHostNames = [ "10.0.0.4" "2001:db8::4" ];
      hostPublicKeyLiteral = quxPublicKey;
      systems = [ "x86_64-linux" "i686-linux" ];
      maxJobs = 8;
      speedFactor = 1;
      supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
      sshUserName = "syd";
    };
  };
  extraRemoteBuildHosts = {
    baz = {
      hostName = "baz.example.com";
      alternateHostNames = [ "10.0.0.3" "2001:db8::3" ];
      hostPublicKeyLiteral = bazPublicKey;
      systems = [ "aarch64-linux" ];
      maxJobs = 6;
      speedFactor = 2;
      supportedFeatures = [ "big-parallel" "nixos-test" ];
      sshUserName = "alice";
      sshKeyLiteral = alicePrivateKey;
    };
  };
  noExtraBuildHosts = makeTestPython {

    name = "build-host";
    meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

    nodes = {
      machine = { config, ... }: {
        nixpkgs.localSystem.system = system;
        imports = pkgs.lib.hacknix.modules
          ++ pkgs.lib.hacknix.testing.testModules;

        # Use the test key deployment system.
        deployment.reallyReallyEnable = true;

        hacknix.build-host = {
          enable = true;
          buildMachines = remoteBuildHosts;
        };
      };
    };

    testScript = { nodes, ... }:
      let
      in
      ''
        start_all()

        with subtest("Check SSH keys"):
            machine.succeed(
                "diff ${alicePrivateKeyFile} /etc/nix/alice_at_foo"
            )
            machine.succeed("[[ `stat -c%a /etc/nix/alice_at_foo` -eq 400 ]]")
            machine.succeed("[[ `stat -c%a /etc/nix/alice_at_foo` -eq 400 ]]")
            machine.succeed(
                "diff ${bobPrivateKeyFile} /etc/nix/bob_at_bar"
            )
            machine.succeed("[[ `stat -c%a /etc/nix/bob_at_bar` -eq 400 ]]")
            machine.succeed("[[ `stat -c%U /etc/nix/bob_at_bar` -eq root ]]")

        with subtest("Check /etc/nix/machines"):
            machine.succeed(
                "diff -w ${expectedMachinesFile} /etc/nix/machines"
            )

        with subtest("Check /etc/ssh/ssh_known_hosts"):
            foo_key = "foo.example.com,10.0.0.1,2001:db8::1 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsvvICWc8HDQkkIwIaHQ2xuHieJyLULqe1Z/xeJQRzi"
            bar_key = "bar.example.com,10.0.0.2,2001:db8::2 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAEBze0BfSijN9vRgvLOyJacAo7rCgr9u96hGWNkyPL"
            ssh_known_hosts = machine.succeed("cat /etc/ssh/ssh_known_hosts")
            assert foo_key in ssh_known_hosts
            assert bar_key in ssh_known_hosts
      '';
  };
  extraBuildHosts = makeTestPython {

    name = "build-host-extra-build-hosts";
    meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

    nodes = {
      machine = { config, ... }: {
        nixpkgs.localSystem.system = system;
        imports = pkgs.lib.hacknix.modules
          ++ pkgs.lib.hacknix.testing.testModules;

        # Use the test key deployment system.
        deployment.reallyReallyEnable = true;

        hacknix.build-host = {
          enable = true;
          buildMachines = remoteBuildHosts;
          extraBuildMachines = extraRemoteBuildHosts;
        };
      };
    };

    testScript = { nodes, ... }:
      let
      in
      ''
        start_all()

        with subtest("Check SSH keys"):
            machine.succeed(
                "diff ${alicePrivateKeyFile} /etc/nix/alice_at_foo"
            )
            machine.succeed("[[ `stat -c%a /etc/nix/alice_at_foo` -eq 400 ]]")
            machine.succeed("[[ `stat -c%U /etc/nix/alice_at_foo` -eq root ]]")
            machine.succeed(
                "diff ${bobPrivateKeyFile} /etc/nix/bob_at_bar"
            )
            machine.succeed("[[ `stat -c%a /etc/nix/bob_at_bar` -eq 400 ]]")
            machine.succeed("[[ `stat -c%U /etc/nix/bob_at_bar` -eq root ]]")
            machine.succeed(
                "diff ${alicePrivateKeyFile} /etc/nix/alice_at_baz"
            )
            machine.succeed("[[ `stat -c%a /etc/nix/alice_at_baz` -eq 400 ]]")
            machine.succeed("[[ `stat -c%U /etc/nix/alice_at_baz` -eq root ]]")

            machine.wait_for_file("/etc/nix/remote-builder")
            machine.succeed("[[ `stat -c%a /etc/nix/remote-builder` -eq 600 ]]")
            machine.succeed("[[ `stat -c%U /etc/nix/remote-builder` -eq root ]]")
            machine.succeed("[[ `stat -c%a /etc/nix/remote-builder.pub` -eq 644 ]]")
            machine.succeed("[[ `stat -c%U /etc/nix/remote-builder.pub` -eq root ]]")

        with subtest("Check /etc/nix/machines"):
            machine.succeed(
                "diff -w ${expectedMachinesFile} /etc/nix/machines"
            )

        with subtest("Check /etc/nix/extra-machines"):
            machine.succeed(
                "diff -w ${expectedExtraMachinesFile} /etc/nix/extra-machines"
            )

        with subtest("Check /etc/ssh/known_hosts"):
            foo_key = "foo.example.com,10.0.0.1,2001:db8::1 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsvvICWc8HDQkkIwIaHQ2xuHieJyLULqe1Z/xeJQRzi"
            bar_key = "bar.example.com,10.0.0.2,2001:db8::2 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAEBze0BfSijN9vRgvLOyJacAo7rCgr9u96hGWNkyPL"
            baz_key = "baz.example.com,10.0.0.3,2001:db8::3 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds"
            qux_key = "qux.example.com,10.0.0.4,2001:db8::4 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFUD3f/kxQgu+DJHjy/3jWqqTZk6rnWrwBabt+WTBWfT"
            ssh_known_hosts = machine.succeed("cat /etc/ssh/ssh_known_hosts")
            assert foo_key in ssh_known_hosts
            assert bar_key in ssh_known_hosts
            assert baz_key in ssh_known_hosts
            assert qux_key in ssh_known_hosts

        with subtest("Check /etc/ssh/ssh_config"):
            host = "Host bar.example.com"
            port = "Port 2002"
            ssh_config = machine.succeed("cat /etc/ssh/ssh_config")
            assert host in ssh_config
            assert port in ssh_config
      '';
  };
in
{ inherit noExtraBuildHosts extraBuildHosts; }
