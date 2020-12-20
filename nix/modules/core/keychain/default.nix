{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hacknix.keychain;
in
{
  options.hacknix.keychain = {
    keys = mkOption {
      default = { };
      example = { secret-key.text = "passw0rd"; };
      type = types.attrsOf pkgs.lib.types.key;
      description = ''
        An attrset for stashing file-based keys during configuration.
        Each key is of type <literal>key</literal>, compatible with
        the NixOps <literal>keyType</literal>.

        The <literal>key</literal> type ensures that secrets cannot
        accidentally be written to the Nix store, because it is not
        possible to specify a key path in the store.

        To get the path where the key will be deployed by a deployment
        system, use the <literal>path</literal> attribute.
      '';
    };
  };
}
