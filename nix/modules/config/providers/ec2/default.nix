{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.hacknix.ec2;
in
{
  options.hacknix.ec2 = {
    enable = lib.mkEnableOption ''
      configuration defaults for EC2 instances.

      This module imports all extra modules needed to run NixOS on an
      EC2 system, and disables the <literal>amazon-init</literal>
      service, which looks for Nix expressions in the instance's user
      data and rebuilds the system based on that data. We disable this
      service because we assume that the system will be configured and
      deployed by a service like NixOps, instead.
    '';
  };

  config = lib.mkIf cfg.enable {
    ec2.hvm = true;
    systemd.services.amazon-init.wantedBy = pkgs.lib.mkForce [ ];
  };
}
