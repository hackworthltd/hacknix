# # Dummy (and insecure!) secret deployments for our tests.
##
## Do not use this in production -- it will put secrets into the Nix
## store.
##

## Note: this module intentionally uses the same "deployment"
## namespace as NixOps. This ensures that if you're trying to use it
## in production with NixOps, you will notice because of the namespace
## clashes.

# This code is derived from the key deployment code in NixOps. As a
# derivative work, it is covered by the LGPL. See the LICENSE file
# included with this source distribution.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.deployment;
  keychain = config.hacknix.keychain;
  enabled = cfg.reallyReallyEnable;

  deployKeys = (concatStrings (mapAttrsToList (name: value:
    let
      keyFile = pkgs.writeText name value.text;
      destDir = toString value.destDir;
    in ''
      if test ! -d ${destDir}
      then
          mkdir -p ${destDir} -m 0750
          chown ${value.user}:${value.group} ${destDir}
      fi
      install -m ${value.permissions} -o ${value.user} -g ${value.group} ${keyFile} ${destDir}/${name}
    '') cfg.keys));

in {
  options.deployment = {
    reallyReallyEnable = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Faux NixOps-style secret deployments. <emphasis>FOR TESTING
        ONLY. DO NOT USE ON PRODUCTION BUILDS.</emphasis>

        Warning: this service <emphasis>will</emphasis> write secrets
        to the Nix store. It is designed explicitly to do so.
      '';
    };

    keys = mkOption {
      visible = false;
      readOnly = true;
      type = types.attrsOf pkgs.lib.types.key;
      description = ''
        Equivalent to NixOps's <option>deployment.keys</option>,
        except that enabling this test deployment mechanism will
        automatically copy the keys from
        <option>hacknix.keychain.keys</option>, whereas with actual
        NixOps, you must do this bit yourself.

        Note: this option is invisible and read-only. It should not be
        assigned by the user. It is here only to guarantee a namespace
        conflict with NixOps, in case this module is mistakenly
        enabled in an actual deployment.
      '';
    };
  };

  config = mkIf enabled {

    warnings = [
      ("NOTE: The hacknix faux NixOps secret deployment system has been "
        + "enabled. This system is inteded for use ONLY IN TESTING. This "
        + "system WILL copy secrets to the Nix store. Do NOT use this system "
        + "in production!")
    ];

    deployment.keys = keychain.keys;

    # Emulate NixOps.
    system.activationScripts.nixops-keys = stringAfter [ "users" "groups" ] ''
      mkdir -p /run/keys -m 0750
      chown root:keys /run/keys
      ${deployKeys}
      touch /run/keys/done
    '';
  };
}
