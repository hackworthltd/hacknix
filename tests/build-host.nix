# Note: this test doesn't perform any remote builds; it merely ensures
# that the files and keys needed to support remote builds are set up
# correctly.

{ system ? "x86_64-linux", pkgs, makeTest, ... }:

let

  expectedMachinesFile = pkgs.writeText "machines" ''
    ssh://bob@bar.example.com x86_64-linux,i686-linux /etc/nix/bob_at_bar 16 2 benchmark,big-parallel,kvm,nixos-test benchmark
    ssh://alice@foo.example.com x86_64-darwin /etc/nix/alice_at_foo 4 1 big-parallel
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

  noExtraBuildHosts = makeTest rec {

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
      in ''
        startAll;

        subtest "check-ssh-keys", sub {
          $machine->succeed("diff ${alicePrivateKeyFile} /etc/nix/alice_at_foo");
          $machine->succeed("[[ `stat -c%a /etc/nix/alice_at_foo` -eq 400 ]]");
          $machine->succeed("[[ `stat -c%a /etc/nix/alice_at_foo` -eq 400 ]]");
          $machine->succeed("diff ${bobPrivateKeyFile} /etc/nix/bob_at_bar");
          $machine->succeed("[[ `stat -c%a /etc/nix/bob_at_bar` -eq 400 ]]");
          $machine->succeed("[[ `stat -c%U /etc/nix/bob_at_bar` -eq root ]]");
        };

        subtest "check-etc-nix-machines", sub {
          $machine->succeed("diff -w ${expectedMachinesFile} /etc/nix/machines");
        };

        subtest "check-ssh_known_hosts", sub {
          my $foostring = quotemeta ("foo.example.com,10.0.0.1,2001:db8::1 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsvvICWc8HDQkkIwIaHQ2xuHieJyLULqe1Z/xeJQRzi");
          my $barstring = quotemeta ("bar.example.com,10.0.0.2,2001:db8::2 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAEBze0BfSijN9vRgvLOyJacAo7rCgr9u96hGWNkyPL");
          my $ssh_known_hosts = $machine->succeed("cat /etc/ssh/ssh_known_hosts");
          $ssh_known_hosts =~ /$foostring/ or die "/etc/ssh/ssh_known_hosts is missing expected `foo` host key";
          $ssh_known_hosts =~ /$barstring/ or die "/etc/ssh/ssh_known_hosts is missing expected `bar` host key";
        };
      '';
  };

  extraBuildHosts = makeTest rec {

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
      in ''
        startAll;

        subtest "check-ssh-keys", sub {
          $machine->succeed("diff ${alicePrivateKeyFile} /etc/nix/alice_at_foo");
          $machine->succeed("[[ `stat -c%a /etc/nix/alice_at_foo` -eq 400 ]]");
          $machine->succeed("[[ `stat -c%U /etc/nix/alice_at_foo` -eq root ]]");
          $machine->succeed("diff ${bobPrivateKeyFile} /etc/nix/bob_at_bar");
          $machine->succeed("[[ `stat -c%a /etc/nix/bob_at_bar` -eq 400 ]]");
          $machine->succeed("[[ `stat -c%U /etc/nix/bob_at_bar` -eq root ]]");
          $machine->succeed("diff ${alicePrivateKeyFile} /etc/nix/alice_at_baz");
          $machine->succeed("[[ `stat -c%a /etc/nix/alice_at_baz` -eq 400 ]]");
          $machine->succeed("[[ `stat -c%U /etc/nix/alice_at_baz` -eq root ]]");
        };

        subtest "check-etc-nix-machines", sub {
          $machine->succeed("diff -w ${expectedMachinesFile} /etc/nix/machines");
        };

        subtest "check-etc-nix-extra-machines", sub {
          $machine->succeed("diff -w ${expectedExtraMachinesFile} /etc/nix/extra-machines");
        };

        subtest "check-ssh_known_hosts", sub {
          my $foostring = quotemeta ("foo.example.com,10.0.0.1,2001:db8::1 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsvvICWc8HDQkkIwIaHQ2xuHieJyLULqe1Z/xeJQRzi");
          my $barstring = quotemeta ("bar.example.com,10.0.0.2,2001:db8::2 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAEBze0BfSijN9vRgvLOyJacAo7rCgr9u96hGWNkyPL");
          my $bazstring = quotemeta ("baz.example.com,10.0.0.3,2001:db8::3 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds");
          my $ssh_known_hosts = $machine->succeed("cat /etc/ssh/ssh_known_hosts");
          $ssh_known_hosts =~ /$foostring/ or die "/etc/ssh/ssh_known_hosts is missing expected `foo` host key";
          $ssh_known_hosts =~ /$barstring/ or die "/etc/ssh/ssh_known_hosts is missing expected `bar` host key";
          $ssh_known_hosts =~ /$bazstring/ or die "/etc/ssh/ssh_known_hosts is missing expected `baz` host key";
        };

        subtest "check-ssh_config", sub {
          my $hoststring = quotemeta ("Host bar.example.com");
          my $portstring = quotemeta ("Port 2002");
          my $ssh_config = $machine->succeed("cat /etc/ssh/ssh_config");
          $ssh_config =~ /$hoststring/ or die "/etc/ssh/ssh_config is missing expected `Host bar.example.com` line";
          $ssh_config =~ /$portstring/ or die "/etc/ssh/ssh_config is missing expected `Port 2002` line";
        };
      '';
  };

in { inherit noExtraBuildHosts extraBuildHosts; }
