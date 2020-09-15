self: super:
let
  nixops-network = super.lib.hacknix.nixops.network {
    pluginNixExprs = [ ];
    networkExprs = [
      ./nixops/logical.nix
      ./nixops/physical.nix
    ];
    uuid = "dummy";
    deploymentName = "nixops-network-deployments";
    args = { };
  };
  nixops-network-deployments = super.lib.hacknix.nixops.deployments nixops-network;

in
{
  inherit nixops-network-deployments;
}
