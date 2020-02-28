{ config, lib, pkgs, ... }:

let

  cfg = config.hacknix.freeradius;

  # Module overrides.
  eap = ./static/eap;

  serverKeyName = "freeradius-server";

  # Client configuration is complicated because we need to keep the
  # secrets out of the store.

  clientKeyName = name: "freeradius-client-${name}.secret";

  clientsConf =
  let
    clientsList = lib.mapAttrsToList (_: client: client) cfg.clients;
    genClientConf = client:
    let
      keys = config.hacknix.keychain.keys;
      keyName = clientKeyName client.name;
      keyPath = keys."${keyName}".path;
    in
    ''
      client ${client.name} {
        ipaddr = ${client.ipv4}
        proto = *
        require_message_authenticator = no
        nas_type = other
        limit {
          max_connections = 16
          lifetime = 0
          idle_timeout = 30
        }
        $INCLUDE ${keyPath}
      }

      client ${client.name}_ipv6 {
        ipaddr = ${client.ipv6}
        proto = *
        require_message_authenticator = no
        nas_type = other
        limit {
          max_connections = 16
          lifetime = 0
          idle_timeout = 30
        }
        $INCLUDE ${keyPath}
      }
    '';
  in
    pkgs.writeText "clients.conf" (lib.concatMapStringsSep "\n\n" genClientConf clientsList);

  files = import ./files.nix {
    inherit pkgs lib config;
  };

  siteDefault = import ./site-default.nix {
    inherit pkgs lib config;
  };

  radiusdConf = import ./radiusd.nix {
    inherit pkgs lib config;
  };

  raddbDir = pkgs.symlinkJoin {
    name = "raddb";
    paths = [
      "${pkgs.freeradius}/etc/raddb"
    ];
    postBuild =
    let
      radiusdConfPath = "${radiusdConf}";
      clientsConfPath = "${clientsConf}";
      serverKeyPath = config.hacknix.keychain.keys."${serverKeyName}".path;
      caPath = "${cfg.tls.caPath}";
      serverCertPath = "${cfg.tls.serverCertificate}";
      dhPath = "${pkgs.ffdhe3072Pem}";
      eapPath = "${eap}";
      siteDefaultPath = "${siteDefault}";
      filesPath = "${files.files}";
      authorizedMacsPath = "${files.authorizedMacs}";
    in
    ''
      rm -f $out/clients.conf
      rm -f $out/radiusd.conf
      ln -s ${radiusdConfPath} $out/radiusd.conf
      ln -s ${clientsConfPath} $out/clients.conf

      rm -f $out/certs/*
      ln -s ${serverCertPath} $out/certs/server.pem
      ln -s ${dhPath} $out/certs/dh
      ln -s ${serverKeyPath} $out/certs/server.key

      rm -f $out/mods-config/files/authorize
      touch $out/mods-config/files/authorize

      rm -f $out/mods-available/files
      ln -s ${filesPath} $out/mods-available/files
      ln -s ${authorizedMacsPath} $out/mods-config/files/authorized_macs

      rm -f $out/mods-available/eap
      ln -s ${eapPath} $out/mods-available/eap

      rm -f $out/sites-enabled/default
      rm -f $out/sites-enabled/inner-tunnel
      ln -s ${siteDefaultPath} $out/sites-enabled/default
    '';
  };

in
lib.mkIf (cfg.enable) {
  environment.etc."raddb".source = raddbDir;

  systemd.services.freeradius = {
    restartTriggers = [ config.environment.etc."raddb".source ];
  };

  hacknix.keychain.keys = (lib.mapAttrs' (_: client: lib.nameValuePair (clientKeyName client.name) {
    destDir = cfg.secretsDir;
    text = "secret = ${client.secretLiteral}";
    user = "radius";
    group = "wheel";
    permissions = "0400";
  }) cfg.clients)
  // {
    "${serverKeyName}" = {
      destDir = cfg.secretsDir;
      text = cfg.tls.serverCertificateKeyLiteral;
      user = "radius";
      group = "wheel";
      permissions = "0400";
    };
  };
}
