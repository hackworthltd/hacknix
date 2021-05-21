final: prev:
let
  vault-plugin-secrets-github = final.callPackage ../pkgs/vault-plugin-secrets-github { };
  vault-plugins = final.callPackage ../pkgs/vault-plugins { };
in
{
  inherit vault-plugin-secrets-github;
  inherit (vault-plugins) vault-plugins register-vault-plugins;
}
