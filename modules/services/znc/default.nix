# # A znc module that, unlike the upstream module, does not write IRC
## secrets to the Nix store. It does this by treating the entire ZNC
## config file, which contains cleartext passwords, as a secret.
##
## This means the ZNC config file must be copied to the host machine
## out-of-band, e.g., via NixOps.

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.qx-znc;

  deployed-config = config.hacknix.keychain.keys.znc-config.path;

  defaultUser = "znc"; # Default user to own process.

  # Default user and pass:
  # un=znc
  # pw=nixospass

  defaultUserName = "znc";
  defaultPassBlock =
    "\n        <Pass password>\n                Method = sha256\n                Hash = e2ce303c7ea75c571d80d8540a8699b46535be6a085be3414947d638e48d9e93\n                Salt = l5Xryew4g*!oa(ECfX2o\n        </Pass>\n  ";

  modules = pkgs.buildEnv {
    name = "znc-modules";
    paths = cfg.modulePackages;
  };

  networkOpts = { ... }: {
    options = {
      server = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        example = "chat.freenode.net";
        description = ''
          IRC server address.
        '';
      };

      port = mkOption {
        type = pkgs.lib.types.port;
        default = 6697;
        example = 6697;
        description = ''
          IRC server port.
        '';
      };

      userName = mkOption {
        default = "";
        example = "johntron";
        type = types.str;
        description = ''
          A nick identity specific to the IRC server.
        '';
      };

      password = mkOption {
        type = types.str;
        default = "";
        description = ''
          IRC server password, such as for a Slack gateway.
        '';
      };

      useSSL = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to use SSL to connect to the IRC server.
        '';
      };

      modulePackages = mkOption {
        type = types.listOf types.package;
        default = [];
        example = [ "pkgs.zncModules.push" "pkgs.zncModules.fish" ];
        description = ''
          External ZNC modules to build.
        '';
      };

      modules = mkOption {
        type = types.listOf pkgs.lib.types.nonEmptyStr;
        default = [ "simple_away" ];
        example = literalExample "[ simple_away sasl ]";
        description = ''
          ZNC modules to load.
        '';
      };

      channels = mkOption {
        type = types.listOf pkgs.lib.types.nonEmptyStr;
        default = [];
        example = [ "nixos" ];
        description = ''
          IRC channels to join.
        '';
      };

      hasBitlbeeControlChannel = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to add the special Bitlbee operations channel.
        '';
      };

      extraConf = mkOption {
        default = "";
        type = types.lines;
        example = ''
          Encoding = ^UTF-8
          FloodBurst = 4
          FloodRate = 1.00
          IRCConnectEnabled = true
          Ident = johntron
          JoinDelay = 0
          Nick = johntron
        '';
        description = ''
          Extra config for the network.
        '';
      };
    };
  };
in
{

  disabledModules = [
    "services/networking/znc/default.nix"
    "services/networking/znc/options.nix"
  ];

  ###### Interface

  options = {
    services.qx-znc = {
      enable = mkEnableOption "a ZNC service for a user.";

      configLiteral = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        description = ''
          The path to the ZNC configuration file on the target
          machine. You can create this file from the ZNC module
          configuration by passing the configuration to the
          <literal>mkZncConf</literal> function.

          As this configuration contains passwords, it will be treated
          as a secret and not copied to the Nix store.
        '';
      };

      user = mkOption {
        default = "znc";
        example = "john";
        type = pkgs.lib.types.nonEmptyStr;
        description = ''
          The name of an existing user account to use to own the ZNC server process.
          If not specified, a default user will be created to own the process.
        '';
      };

      group = mkOption {
        default = "znc";
        example = "users";
        type = pkgs.lib.types.nonEmptyStr;
        description = ''
          Group to own the ZNCserver process.
        '';
      };

      dataDir = mkOption {
        default = "/var/lib/znc";
        example = "/home/john/.znc/";
        type = types.path;
        description = ''
          The data directory. Used for configuration files and modules.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to open ports in the firewall for ZNC.
        '';
      };

      zncConf = mkOption {
        default = "";
        example = "See: http://wiki.znc.in/Configuration";
        type = types.lines;
        description = ''
          Config file as generated with `znc --makeconf` to use for the whole ZNC configuration.
          If specified, `confOptions` will be ignored, and this value, as-is, will be used.
          If left empty, a conf file with default values will be used.
        '';
      };

      confOptions = {
        modules = mkOption {
          type = types.listOf pkgs.lib.types.nonEmptyStr;
          default = [ "webadmin" "adminlog" ];
          example = [ "partyline" "webadmin" "adminlog" "log" ];
          description = ''
            A list of modules to include in the `znc.conf` file.
          '';
        };

        userModules = mkOption {
          type = types.listOf pkgs.lib.types.nonEmptyStr;
          default = [ "chansaver" "controlpanel" ];
          example = [ "chansaver" "controlpanel" "fish" "push" ];
          description = ''
            A list of user modules to include in the `znc.conf` file.
          '';
        };

        userName = mkOption {
          default = defaultUserName;
          example = "johntron";
          type = pkgs.lib.types.nonEmptyStr;
          description = ''
            The user name used to log in to the ZNC web admin interface.
          '';
        };

        networks = mkOption {
          default = {};
          type = with types; attrsOf (submodule networkOpts);
          description = ''
            IRC networks to connect the user to.
          '';
          example = {
            "freenode" = {
              server = "chat.freenode.net";
              port = 6697;
              useSSL = true;
              modules = [ "simple_away" ];
            };
          };
        };

        admin = mkOption {
          default = true;
          type = types.bool;
          description = ''
            Specifies whether the user has admin rights in ZNC.
          '';
        };

        nick = mkOption {
          default = "znc-user";
          example = "john";
          type = pkgs.lib.types.nonEmptyStr;
          description = ''
            The default primary IRC nick.
          '';
        };

        altNick = mkOption {
          default = "${cfg.confOptions.nick}_";
          example = "john_";
          type = pkgs.lib.types.nonEmptyStr;
          description = ''
            The default alternate IRC nick used if the primary IRC
            nick is already in use.
          '';
        };

        ident = mkOption {
          default = cfg.confOptions.nick;
          example = "john";
          type = pkgs.lib.types.nonEmptyStr;
          description = ''
            The default IRC ident value.
          '';
        };

        realName = mkOption {
          default = cfg.confOptions.nick;
          example = "Joe User";
          type = pkgs.lib.types.nonEmptyStr;
          description = ''
            The default displayed IRC real name.
          '';
        };

        passBlock = mkOption {
          example = defaultPassBlock;
          type = pkgs.lib.types.nonEmptyStr;
          description = ''
            Generate with `nix-shell -p znc --command "znc --makepass"`.
            This is the password used to log in to the ZNC web admin interface.
          '';
        };

        host = mkOption {
          type = types.str;
          example = "localhost";
          default = "";
          description = ''
            An optional hostname or IP address on which ZNC listens.
          '';
        };

        port = mkOption {
          default = 5000;
          example = 5000;
          type = pkgs.lib.types.port;
          description = ''
            Specifies the port on which to listen.
          '';
        };

        useSSL = mkOption {
          default = true;
          type = types.bool;
          description = ''
            Indicates whether the ZNC server should use SSL when listening on the specified port. A self-signed certificate will be generated.
          '';
        };

        hideVersion = mkOption {
          default = false;
          type = types.bool;
          description = ''
            If true, don't display the ZNC version in the web
            interface, nor in CTCP VERSION replies.
          '';
        };

        extraUserConf = mkOption {
          default = "";
          type = types.lines;
          description = ''
            Extra user config to `znc.conf` file.
          '';
        };

        uriPrefix = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/znc/";
          description = ''
            An optional URI prefix for the ZNC web interface. Can be
            used to make ZNC available behind a reverse proxy.
          '';
        };

        extraZncConf = mkOption {
          default = "";
          type = types.lines;
          description = ''
            Extra config to `znc.conf` file.
          '';
        };
      };

      modulePackages = mkOption {
        type = types.listOf types.package;
        default = [];
        example =
          literalExample "[ pkgs.zncModules.fish pkgs.zncModules.push ]";
        description = ''
          A list of global znc module packages to add to znc.
        '';
      };

      mutable = mkOption {
        default = true;
        type = types.bool;
        description = ''
          Indicates whether to allow the contents of the `dataDir` directory to be changed
          by the user at run-time.
          If true, modifications to the ZNC configuration after its initial creation are not
            overwritten by a NixOS system rebuild.
          If false, the ZNC configuration is rebuilt by every system rebuild.
          If the user wants to manage the ZNC service using the web admin interface, this value
            should be set to true.
        '';
      };

      extraFlags = mkOption {
        default = [];
        example = [ "--debug" ];
        type = types.listOf pkgs.lib.types.nonEmptyStr;
        description = ''
          Extra flags to use when executing znc command.
        '';
      };
    };
  };

  ###### Implementation

  config = mkIf cfg.enable {

    hacknix.assertions.moduleHashes."services/networking/znc/default.nix" =
      "79c9902ec5d893eb5e1cd59b0ef7d2dff05d440981ced4ab9373aa480303ba2a";

    hacknix.keychain.keys.znc-config = { text = cfg.configLiteral; };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.confOptions.port ]; };

    systemd.services.znc = rec {
      description = "ZNC Server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "znc-config-key.service" ];
      after = [ "network.service" ] ++ wants;

      serviceConfig = {
        PermissionsStartOnly = true;
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        ExecStop = "${pkgs.coreutils}/bin/kill -INT $MAINPID";
      };
      preStart = ''
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDir}/configs || true
        ${pkgs.coreutils}/bin/chmod 0700 ${cfg.dataDir}/configs
        ${pkgs.coreutils}/bin/chown ${cfg.user} ${cfg.dataDir}/configs

        # If immutable, regenerate conf file every time.
        ${optionalString (!cfg.mutable) ''
        ${pkgs.coreutils}/bin/echo "znc is set to be system-managed. Now deleting old znc.conf file to be regenerated."
        ${pkgs.coreutils}/bin/rm -f ${cfg.dataDir}/configs/znc.conf
      ''}

        # Ensure essential files exist.
        if [[ ! -e ${cfg.dataDir}/configs/znc.conf ]]; then
            ${pkgs.coreutils}/bin/echo "No znc.conf file found in ${cfg.dataDir}. Creating one now."
            while [[ ! -e ${deployed-config} ]]; do
              echo "Waiting for config file."
              sleep 10
            done
            ${pkgs.coreutils}/bin/cp --no-clobber ${deployed-config} ${cfg.dataDir}/configs/znc.conf
            ${pkgs.coreutils}/bin/chmod 0640 ${cfg.dataDir}/configs/znc.conf
            ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${cfg.dataDir}/configs/znc.conf
        fi

        if [[ ! -e ${cfg.dataDir}/znc.pem ]]; then
          ${pkgs.coreutils}/bin/echo "No znc.pem file found in ${cfg.dataDir}. Creating one now."
          ${pkgs.znc}/bin/znc --makepem --datadir ${cfg.dataDir}
        fi

        # Symlink modules
        rm ${cfg.dataDir}/modules || true
        ln -fs ${modules}/lib/znc ${cfg.dataDir}/modules
      '';
      script = "${pkgs.znc}/bin/znc --foreground --datadir ${cfg.dataDir} ${
      toString cfg.extraFlags
      }";
    };

    users.users = optionalAttrs (cfg.user == defaultUser) {
      "${cfg.user}" = {
        name = defaultUser;
        description = "ZNC server daemon owner";
        group = defaultUser;
        uid = config.ids.uids.znc;
        home = cfg.dataDir;
        createHome = true;
      };
    };

    users.extraGroups = optionalAttrs (cfg.user == defaultUser) {
      "${cfg.user}" = {
        name = defaultUser;
        gid = config.ids.gids.znc;
        members = [ defaultUser ];
      };
    };
  };
}
