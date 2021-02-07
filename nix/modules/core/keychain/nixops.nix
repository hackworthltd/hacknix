{ config, lib, pkgs, ... }:
let
  keys = config.hacknix.keychain.keys;
  cfg = config.hacknix.keychain.nixops;
in
{
  options.hacknix.keychain.nixops = {
    enable = lib.mkEnableOption "deployment of keychain keys using NixOps.";
  };

  config = lib.mkIf cfg.enable {
    deployment = { inherit keys; };
  };
}
