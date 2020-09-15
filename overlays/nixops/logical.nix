{ system ? "x86_64-linux"
, config ? {
    allowUnfree = true;
  }
, localLib ? import ../../nix/default.nix { inherit system config; }
, pkgs ? localLib.pkgs
}:
let
  ourModules = import ../../modules/module-list.nix;
in
{
  network = {
    description = "hacknix test deployment.";
    nixpkgs = pkgs;
    enableRollback = true;
  };

  defaults = { ... }: {
    imports = ourModules;
  };

  machine1 = { ... }: {
    networking.hostName = "foo";
    networking.domain = "example.com";
  };
}
