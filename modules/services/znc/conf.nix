{ pkgs, zncServiceConfig }:

with pkgs.lib;
let
  mkZncConf = confOpts: ''
    Version = 1.6.3
    ${optionalString confOpts.hideVersion ''
      HideVersion = true
    ''}
    ${concatMapStrings
      (
          n: ''
            LoadModule = ${n}
          ''
        ) confOpts.modules}

    <Listener l>
            ${
      optionalString (confOpts.host != "") ''
        Host = ${confOpts.host}
      ''
    }
            Port = ${toString confOpts.port}
            IPv4 = true
            IPv6 = true
            SSL = ${boolToString confOpts.useSSL}
            ${
      optionalString (confOpts.uriPrefix != null)
          "URIPrefix = ${confOpts.uriPrefix}"
    }
    </Listener>

    <User ${confOpts.userName}>
            ${confOpts.passBlock}
            Admin = ${ if confOpts.admin then "true" else "false"}
            Nick = ${confOpts.nick}
            AltNick = ${confOpts.altNick}
            Ident = ${confOpts.ident}
            RealName = ${confOpts.realName}
            ${
      concatMapStrings
          (
              n: ''
                LoadModule = ${n}
              ''
            ) confOpts.userModules
    }

            ${
      concatStringsSep "\n"
          (
              mapAttrsToList
                  (
                      name: net: ''
                        <Network ${name}>
                            ${
                          concatMapStrings
                              (
                                  m: ''
                                    LoadModule = ${m}
                                  ''
                                ) net.modules
                        }
                            Server = ${net.server} ${optionalString net.useSSL "+"}${
                          toString net.port
                        } ${net.password}
                            ${
                          concatMapStrings
                              (
                                  c: ''
                                    <Chan #${c}>
                                    </Chan>
                                  ''
                                ) net.channels
                        }
                            ${
                          optionalString net.hasBitlbeeControlChannel ''
                            <Chan &bitlbee>
                            </Chan>
                          ''
                        }
                            ${net.extraConf}
                        </Network>
                      ''
                    ) confOpts.networks
            )
    }

            ${confOpts.extraUserConf}
    </User>
    ${confOpts.extraZncConf}
  '';
in
if zncServiceConfig.zncConf != "" then
  zncServiceConfig.zncConf
else
  mkZncConf zncServiceConfig.confOptions
