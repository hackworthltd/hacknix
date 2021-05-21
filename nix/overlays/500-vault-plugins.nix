final: prev:
let
  vault-plugin-secrets-github = final.callPackage ../pkgs/vault-plugin-secrets-github { };
in
{
  inherit vault-plugin-secrets-github;
}
