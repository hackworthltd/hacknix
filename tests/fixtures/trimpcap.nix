{ testingPython, ... }:
with testingPython;
let
  pcapFile = ../testfiles/DHCPv6.pcap;
  testSize = pkgs.writeScript "testSize" ''
    #!${pkgs.stdenv.shell} -e
    [[ `(stat -c%s "$1")` -gt `(stat -c%s "$2")` ]]
  '';
in
makeTest rec {
  skipLint = true;
  name = "trimpcap";
  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  machine = { config, pkgs, ... }: { };

  testScript = { nodes, ... }:
    let
      ngrep = nodes.machine.pkgs.ngrep;
      trimpcap = nodes.machine.pkgs.trimpcap;
    in
    ''
      # Sanity check that the file is what we think it is. Note that
      # ngrep doesn't return proper error codes, so we have to grep its
      # grep.
      machine.succeed(
          "${ngrep}/bin/ngrep -I ${pcapFile} host ff02::16 | grep ff02::16"
      )

      with subtest("pcap-is-trimmed"):
        machine.succeed("cp ${pcapFile} /tmp/test.pcap")
        assert "Dataset reduced by 62.38% = 1015 bytes" in machine.succeed("${trimpcap}/bin/trimpcap --flowsize 512 /tmp/test.pcap")

      with subtest("trimmed-pcap-is-valid"):
        machine.succeed("${ngrep}/bin/ngrep -I /tmp/test.pcap.trimmed host ff02::16 | grep ff02::16")

      with subtest( "trim-extension"):
        machine.succeed("${trimpcap}/bin/trimpcap --flowsize 512 --extension .foo /tmp/test.pcap")
        machine.succeed("[ -f /tmp/test.pcap.foo ]")
    '';
}
