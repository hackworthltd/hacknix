{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let

  imports = pkgs.lib.hacknix.modules;

in
makeTestPython {
  name = "hwutils";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  machine = { pkgs, config, ... }: {
    nixpkgs.localSystem.system = system;
    inherit imports;

    hacknix.hardware.hwutils.enable = true;
  };

  testScript = { nodes, ... }: ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("lspci")
    machine.succeed("lsusb")
  '';
}
