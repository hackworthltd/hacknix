{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.hacknix.defaults.nginx;
  enabled = cfg.enable;
  nginx_enabled = config.services.nginx.enable;
in
{
  options.hacknix.defaults.nginx = {

    enable = mkEnableOption ''
      the hacknix nginx configuration defaults. These include
      NixOS-recommended compression, proxy, and optimization settings.
      It also enables the Mozilla-recommended "modern" SSL
      configuration for Nginx. In addition, nginx's server tokens are
      disabled.

      Note that enabling this option does not enable the nginx
      service itself; it simply ensures that any nginx services you
      run on this host will be configured with these default
      settings.
    '';

  };

  config = mkIf enabled {

    services.nginx = {

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;

      serverTokens = false;

      # Mozilla recommendations. See
      # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&guideline=5.6

      sslCiphers = pkgs.lib.security.sslModernCiphers;
      sslProtocols = "TLSv1.2 TLSv1.3";
      appendHttpConfig = ''
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;
        ssl_prefer_server_ciphers on;

        # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
        add_header Strict-Transport-Security max-age=15768000;

        ssl_stapling on;
        ssl_stapling_verify on;
      '';

    };

  };

}
