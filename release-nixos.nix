let
  lib = import nix/default.nix { };
  inherit (lib) fixedNixpkgs;
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
    overlays = lib.overlays;
  }
}:

with import (fixedNixpkgs + "/pkgs/top-level/release-lib.nix")
{
  inherit supportedSystems scrubJobs nixpkgsArgs;
};
let
  makeTestPython = import (fixedNixpkgs + "/nixos/tests/make-test-python.nix");

  importTest = fn: args: system:
    import fn ({ inherit system pkgs; } // args);
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

  discoverTests = val:
    if !lib.isAttrs val then val
    else if lib.hasAttr "test" val then callTest val
    else lib.mapAttrs (n: s: discoverTests s) val;
  handleTest = path: args:
    discoverTests (import path ({
      inherit system makeTestPython pkgs;
    } // args));
  handleTestOn = systems: path: args:
    if elem system systems then handleTest path args
    else { };
  tests = {
    accept = handleTest ./tests/accept.nix { };
    apcupsd-net = handleTest ./tests/apcupsd-net.nix { };
    build-host = handleTest ./tests/build-host.nix { };
    custom-cacert = handleTest ./tests/custom-cacert.nix { };
    dovecot = handleTest ./tests/dovecot.nix { };
    environment = handleTest ./tests/environment.nix { };
    fail2ban = handleTest ./tests/fail2ban.nix { };
    freeradius = handleTest ./tests/freeradius.nix { };
    hwutils = handleTest ./tests/hwutils.nix { };
    hydra-manual-setup = handleTest ./tests/hydra-manual-setup.nix { };
    netsniff-ng = handleTest ./tests/netsniff-ng.nix { };
    networking = handleTest ./tests/networking.nix { };
    opendkim = handleTest ./tests/opendkim.nix { };
    postfix-mta = handleTest ./tests/postfix-mta.nix { };
    postfix-null-client = handleTest ./tests/postfix-null-client.nix { };
    postfix-relay-host = handleTest ./tests/postfix-relay-host.nix { };
    remote-build-host = handleTest ./tests/remote-build-host.nix { };
    security = handleTest ./tests/security.nix { };
    service-status-email = handleTest ./tests/service-status-email.nix { };
    ssh = handleTest ./tests/ssh.nix { };
    sudo = handleTest ./tests/sudo.nix { };
    system = handleTest ./tests/system.nix { };
    tarsnapper = handleTest ./tests/tarsnapper.nix { };
    # Disabled until LRU package issue is fixed.
    #trimpcap = handleTest ./tests/trimpcap.nix {};
    tftpd-hpa = handleTest ./tests/tftpd-hpa.nix { };
    tsoff = handleTest ./tests/tsoff.nix { };
    unbound-multi-instance = handleTest ./tests/unbound-multi-instance.nix { };
    users = handleTest ./tests/users.nix { };
    virtual-ips = handleTest ./tests/virtual-ips.nix { };
    znc = handleTest ./tests/znc.nix { };
  };
in
tests
