final: prev:
let
  terraform-provider-gandi = final.callPackage ../pkgs/terraform-provider-gandi { };
in
{
  inherit terraform-provider-gandi;
}
