{ system ? "x86_64-linux", pkgs, makeTest, ... }:

makeTest {
  name = "fail2ban-config";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  nodes = {

    client = { config, ... }: { nixpkgs.localSystem.system = system; };

    server = { config, ... }: {
      nixpkgs.localSystem.system = system;
      imports = pkgs.lib.hacknix.modules;

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
      startAll;

      $client->waitForUnit("multi-user.target");
      $server->waitForUnit("fail2ban.service");

      subtest "check-ignoreip", sub {
        my $ignoreip = $server->succeed("fail2ban-client -d | grep ignoreip");
        $ignoreip =~ /127\.0\.0\.0\/8/ or die "ignoreip is missing 127.0.0.0/8";
        $ignoreip =~ /::1\/128/ or die "ignoreip is missing ::1/128";
        $ignoreip =~ /192\.168\.0\.0\/24/ or die "ignoreip is missing 192.168.0.0/24";
        $ignoreip =~ /10\.0\.0\.1/ or die "ignoreip is missing 10.0.0.1";
        $ignoreip =~ /2001:db8::\/64/ or die "ignoreip is missing 2001:db8::/64";
        $ignoreip =~ /2001:db8:1::1/ or die "ignoreip is missing 2001:db8:1::1";
      };

      subtest "check-bantime", sub {
        my $bantime = $server->succeed("fail2ban-client -d | grep bantime");
        $bantime =~ /933/ or die "expected bantime 933";
      };

      subtest "check-findtime", sub {
        my $findtime = $server->succeed("fail2ban-client -d | grep findtime");
        $findtime =~ /377/ or die "expected findtime 377";
      };

      subtest "check-maxretry", sub {
        my $maxretry = $server->succeed("fail2ban-client -d | grep maxretry");
        $maxretry =~ /5/ or die "expected maxretry 5";
      };

    '';
}
