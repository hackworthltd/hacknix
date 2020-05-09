# Ensure ntpd starts up. It won't be able to communicate with any NTP
# servers, of course.

{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
makeTestPython {
  name = "ntpd";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  machine = { ... }: {
    nixpkgs.localSystem.system = system;
    imports = pkgs.lib.hacknix.modules
      ++ pkgs.lib.hacknix.testing.testModules;
    services.ntp = {
      enable = true;
      servers = [
        "0.pool.ntp.org"
        "1.pool.ntp.org"
        "2.pool.ntp.org"
        "3.pool.ntp.org"
      ];
    };
  };

  testScript = ''
    machine.wait_for_unit("ntpd.service")
  '';
}
