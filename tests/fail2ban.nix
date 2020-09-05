{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let

  imports = pkgs.lib.hacknix.modules;

in
makeTestPython {
  name = "fail2ban-config";
  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {
    client = { pkgs, config, ... }: { nixpkgs.localSystem.system = system; };
    server = { pkgs, config, ... }: {
      nixpkgs.localSystem.system = system;
      inherit imports;

      hacknix.services.fail2ban = {
        allowList =
          [ "192.168.0.0/24" "10.0.0.1" "2001:db8::/64" "2001:db8:1::1" ];
        bantime = 933;
        findtime = 377;
        maxretry = 5;
      };

      services.fail2ban.enable = true;
    };
  };

  testScript = { nodes, ... }:
    let
    in
    ''
      start_all()

      client.wait_for_unit("multi-user.target")
      server.wait_for_unit("fail2ban.service")

      with subtest("Check ignoreip"):
          ignoreip = server.succeed("fail2ban-client -d | grep ignoreip")
          assert "127.0.0.0/8" in ignoreip
          assert "::1/128" in ignoreip
          assert "192.168.0.0/24" in ignoreip
          assert "10.0.0.1" in ignoreip
          assert "2001:db8::/64" in ignoreip
          assert "2001:db8:1::1" in ignoreip

      with subtest("Check bantime"):
          bantime = server.succeed("fail2ban-client -d | grep bantime")
          assert "933" in bantime

      with subtest("Check findtime"):
          findtime = server.succeed("fail2ban-client -d | grep findtime")
          assert "377" in findtime

      with subtest("Check maxtretry"):
          maxretry = server.succeed("fail2ban-client -d | grep maxretry")
          assert "5" in maxretry
    '';
}
