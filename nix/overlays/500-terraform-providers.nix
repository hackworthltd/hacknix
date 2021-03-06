final: prev:
let
  terraform-provider-cloudflare = final.callPackage ../pkgs/terraform-provider-cloudflare { };
  terraform-provider-gandi = final.callPackage ../pkgs/terraform-provider-gandi { };
  terraform-provider-github = final.callPackage ../pkgs/terraform-provider-github { };
  terraform-provider-keycloak = final.callPackage ../pkgs/terraform-provider-keycloak { };
  terraform-provider-postgresql = final.callPackage ../pkgs/terraform-provider-postgresql { };
in
{
  inherit terraform-provider-cloudflare;
  inherit terraform-provider-gandi;
  inherit terraform-provider-github;
  inherit terraform-provider-keycloak;
  inherit terraform-provider-postgresql;
}
