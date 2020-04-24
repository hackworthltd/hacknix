{ system ? "x86_64-linux", pkgs, makeTest, ... }:

let

  makeEnvTest = name: machineAttrs:
    makeTest {
      name = "environment-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };
      machine = { config, ... }:
        {
          nixpkgs.localSystem.system = system;
          imports = [ ./common/users.nix ] ++ pkgs.lib.hacknix.modules;
        } // machineAttrs;
      testScript = { ... }: ''
        $machine->waitForUnit("multi-user.target");

        subtest "root-no-histfile", sub {
          my $histfile = $machine->fail("${pkgs.bash}/bin/bash -c 'printenv HISTFILE'");
          $histfile eq "" or die "Unexpected output from 'printenv HISTFILE'";
        };

        subtest "user-no-histfile", sub {
          my $whoami = $machine->succeed("su - alice -c 'whoami'");
          $whoami eq "alice\n" or die "su failed";
          my $histfile = $machine->fail("su - alice -c 'printenv HISTFILE'");
          $histfile eq "" or die "Unexpected output from 'printenv HISTFILE'";
        };

        subtest "git-is-in-path", sub {
          $machine->succeed("git init") =~ /Initialized empty Git repository in/;
        };

        subtest "wget-is-in-path", sub {
          $machine->succeed("wget --version") =~ /GNU Wget/;
        };

        subtest "emacs-is-in-path", sub {
          $machine->succeed("emacs --version") =~ /GNU Emacs/;
        };
      '';
    };

in {

  test1 = makeEnvTest "global-enable" { hacknix.defaults.enable = true; };
  test2 =
    makeEnvTest "env-enable" { hacknix.defaults.environment.enable = true; };

}
