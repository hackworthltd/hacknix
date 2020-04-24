{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.hacknix.defaults.nginx;
  enabled = cfg.enable;
  nginx_enabled = config.services.nginx.enable;

in {
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

      ## Mozilla recommendations. See
      ## https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=nginx-1.10.3&openssl=1.0.1e&hsts=yes&profile=modern

      sslCiphers = pkgs.lib.security.sslModernCiphers;

      sslProtocols = "TLSv1.2";

      # Everything that isn't covered by an nginx module option.

      appendHttpConfig = ''
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;
        ssl_prefer_server_ciphers on;

        # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
        add_header Strict-Transport-Security max-age=15768000;

        # OCSP Stapling ---
        # fetch OCSP records from URL in ssl_certificate and cache them
        ssl_stapling on;
        ssl_stapling_verify on;
      '';

    };

  };

}
