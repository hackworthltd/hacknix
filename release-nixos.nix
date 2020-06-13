let
  lib = import nix/default.nix { };
  inherit (lib) fixedNixpkgs pkgs;
in
{ system ? "x86_64-linux"
, supportedSystems ? [ "x86_64-linux" ]
, scrubJobs ? true
, nixpkgsArgs ? {
    config = {
      allowUnfree = true;
      allowBroken = true;
      inHydra = true;
    };
    overlays = lib.singleton pkgs.overlays.all;
  }
}:

with import (fixedNixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs nixpkgsArgs;
};
let
  testing =
    import (fixedNixpkgs + "/nixos/lib/testing.nix") { inherit system pkgs; };
  inherit (testing) makeTest;
  importTest = fn: args: system:
    import fn ({ inherit system pkgs makeTest; } // args);
  callTest = fn: args:
    forAllSystems (system: lib.hydraJob (importTest fn args system));
  callSubTests = fn: args:
    let
      discover = attrs:
        let
          subTests = lib.filterAttrs (lib.const (lib.hasAttr "test")) attrs;
        in
        lib.mapAttrs (lib.const (t: lib.hydraJob t.test)) subTests;
      discoverForSystem = system:
        lib.mapAttrs
          (_: test: { ${system} = test; })
          (discover (importTest fn args system));

      # If the test is only for a particular system, use only the specified
      # system instead of generating attributes for all available systems.
    in
    if args ? system then
      discover (import fn args)
    else
      lib.foldAttrs lib.mergeAttrs { } (map discoverForSystem supportedSystems);
  tests = {
    ## Overlays.
    custom-cacert = callSubTests ./tests/custom-cacert.nix { };
    # Disabled until LRU package issue is fixed.
    #trimpcap = callTest ./tests/trimpcap.nix {};
    tsoff = callSubTests ./tests/tsoff.nix { };

    ## Modules.
    accept = callSubTests ./tests/accept.nix { };
    apcupsd-net = callTest ./tests/apcupsd-net.nix { };
    build-host = callSubTests ./tests/build-host.nix { };
    dovecot = callTest ./tests/dovecot.nix { };
    freeradius = callTest ./tests/freeradius.nix { };
    hydra-manual-setup =
      callTest ./tests/hydra-manual-setup.nix { system = "x86_64-linux"; };
    netsniff-ng = callSubTests ./tests/netsniff-ng.nix { };
    opendkim = callTest ./tests/opendkim.nix { };
    postfix-null-client = callTest ./tests/postfix-null-client.nix { };
    postfix-relay-host = callTest ./tests/postfix-relay-host.nix { };
    remote-build-host = callSubTests ./tests/remote-build-host.nix { };
    service-status-email = callTest ./tests/service-status-email.nix { };
    tarsnapper = callTest ./tests/tarsnapper.nix { };
    tftpd-hpa = callTest ./tests/tftpd-hpa.nix { };
    unbound-multi-instance = callTest ./tests/unbound-multi-instance.nix { };
    virtual-ips = callTest ./tests/virtual-ips.nix { };
    wireguard-dhess = callTest ./tests/wireguard-dhess.nix { };
    znc = callSubTests ./tests/znc.nix { };

    ## Configuration.

    environment = callSubTests ./tests/environment.nix { };
    fail2ban = callTest ./tests/fail2ban.nix { };
    hwutils = callTest ./tests/hwutils.nix { };
    networking = callSubTests ./tests/networking.nix { };
    security = callSubTests ./tests/security.nix { };
    sudo = callSubTests ./tests/sudo.nix { };
    ssh = callSubTests ./tests/ssh.nix { };
    system = callSubTests ./tests/system.nix { };
    users = callSubTests ./tests/users.nix { };
  };

  # Python-flavored tests go here.
  makeTestPython = import (fixedNixpkgs + "/nixos/tests/make-test-python.nix");
  discoverTests = val:
    if !lib.isAttrs val then val
    else if lib.hasAttr "test" val then callTest val
    else lib.mapAttrs (n: s: discoverTests s) val;
  handleTest = path: args:
    discoverTests (import path ({ inherit system pkgs makeTestPython; } // args));
  handleTestOn = systems: path: args:
    if elem system systems then handleTest path args
    else { };
  newTests = {
    ntpd = handleTest ./tests/ntpd.nix { };
    postfix-mta = handleTest ./tests/postfix-mta.nix { };
  };
in
tests // newTests
