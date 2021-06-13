{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.cloudflared;

  cloudflaredConfig = lib.flip lib.recursiveUpdate cfg.extraConfig (
    {
      tunnel = cfg.tunnelName;
      credentials-file = cfg.credentialsFile;
      no-autoupdate = true;
    }
  );

  configFile = pkgs.writeText "cloudflared.yml" (builtins.toJSON cloudflaredConfig);

in
{
  options.services.cloudflared = {
    enable = lib.mkEnableOption ''
      cloudflared, for Cloudflare Argo tunnels to this host.
    '';

    tunnelName = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      example = "hydra";
      description = ''
        The name (or ID) of the Argo tunnel.
      '';
    };

    credentialsFile = lib.mkOption {
      type = pkgs.lib.types.nonStorePath;
      example = "/run/keys/argo.json";
      description = ''
        The path to the file containing the tunnel's credentials,
        which must be created with the <literal>cloudflared tunnel
        create tunnel-name</literal>.

        This path should not be in the Nix store, because it contains
        a secret.
      '';
    };

    extraConfig = lib.mkOption {
      type = pkgs.lib.types.attrs;
      default = { };
      example = {
        ingress = [
          {
            hostname = "hydra.example.com";
            service = "http://localhost:3000";
          }
          {
            service = " http_status:404";
          }
        ];
      };
      description = ''
        Extra configuration to add to the cloudflared config file for
        this tunnel. Put all of your <literal>hostname</literal> and
        <literal>service</literal> definitions here, at the very
        least.
      '';
    };
  };

  config = lib.mkIf cfg.enable
    {
      systemd.services.cloudflared = {
        wantedBy = [ "multi-user.target" ];

        path = with pkgs; [
          cloudflared
        ];

        script = ''
          ${pkgs.cloudflared}/bin/cloudflared tunnel --config ${configFile} run
        '';

        serviceConfig = {
          Restart = "always";
          RestartSec = "30s";
        };
      };

      # Useful for debugging and diagnosing.
      environment.systemPackages = with pkgs; [
        cloudflared
      ];
    };
}
