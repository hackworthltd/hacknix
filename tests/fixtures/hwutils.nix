{ hostPkgs, ... }:
{
  meta = with hostPkgs.lib.maintainers; {
    maintainers = [ dhess ];
  };

  nodes.machine =
    { pkgs, config, ... }:
    {
      hacknix.hardware.hwutils.enable = true;
    };

  testScript =
    { nodes, ... }:
    ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("lspci")
      machine.succeed("lsusb")
    '';
}
