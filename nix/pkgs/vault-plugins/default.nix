{ lib
, stdenv
, vault-plugin-secrets-github
, vault
, writeShellScriptBin
}:

# Vault can't deal with plugins that are symlinks:
# https://github.com/hashicorp/vault/pull/7584
#
# This derivation just copies the Vault plugins we want into a
# directory and packages it.
let

  plugins = [
    vault-plugin-secrets-github
  ];

  installPlugins = builtins.concatStringsSep "\n"
    (
      builtins.map
        (pkg:
          let
            pkgName = lib.getName pkg;
          in
          ''
            install ${pkg}/bin/${pkgName} -m 0555 $lib/lib/${pkgName}
          ''
        )
        plugins
    );

  vault-plugins = stdenv.mkDerivation
    rec {
      pname = "vault-plugins";
      version = "1";

      outputs = [ "out" "lib" ];

      src = ./.;

      installPhase = ''
        mkdir -p $out
        mkdir -p $lib/lib
        ${installPlugins}
      '';

      meta = with lib; {
        description = "A collection of Vault plugins";
        license = licenses.mit;
        maintainers = with maintainers; [ dhess ];
        platforms = platforms.linux;
      };
    };

  # Note: this only works for secrets plugins for the moment.
  register-vault-plugins = writeShellScriptBin "register-vault-plugins" (''
    set -e
  '' +
  (builtins.concatStringsSep "\n"
    (
      builtins.map
        (pkg:
          let pkgName = lib.getName pkg;
          in
          ''
            sha_256="$(sha256sum ${vault-plugins.lib}/lib/${pkgName} | cut -d " " -f1)"

            echo "Re-registering Vault plugin ${pkgName}"
            ${vault}/bin/vault write sys/plugins/catalog/secret/${pkgName} sha_256="$sha_256" command=${pkgName}
            ${vault}/bin/vault write sys/plugins/reload/backend plugin=${pkgName}
          ''
        )
        plugins)
  ));

in
{
  inherit vault-plugins;
  inherit register-vault-plugins;
}
