{ testingPython, ... }:
with testingPython;
let
  makeTsoffTest = name: machineAttrs:
    makeTest {
      name = "tsoff-${name}";
      meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };
      machine = { pkgs, config, ... }: machineAttrs;
      testScript = { nodes, ... }: ''
        machine.wait_for_unit("network.target")

        with subtest("Disables offload"):
            machine.succeed(
                "${nodes.machine.pkgs.tsoff}/bin/tsoff -v eth0"
            )
            assert "tcp-segmentation-offload: off" in machine.succeed(
                "${pkgs.ethtool}/bin/ethtool --show-offload eth0"
            )

        with subtest("Idempotent"):
            # Should just silently succeed.
            machine.succeed(
                "${nodes.machine.pkgs.tsoff}/bin/tsoff -v eth0"
            )
      '';
    };
in
{ defaultTest = makeTsoffTest "default" { }; }
