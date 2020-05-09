{ system ? "x86_64-linux", pkgs, makeTest, ... }:
let
in
makeTest rec {
  name = "hwutils";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  machine = { config, ... }: {
    nixpkgs.localSystem.system = system;
    imports = pkgs.lib.hacknix.modules;
    hacknix.hardware.hwutils.enable = true;
  };

  testScript = { nodes, ... }: ''
    $machine->waitForUnit("multi-user.target");

    subtest "check-lspci", sub {
      $machine->succeed("lspci");
    };

    subtest "check-lsusb", sub {
      $machine->succeed("lsusb");
    };
  '';
}
