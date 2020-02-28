{ config
, lib
, pkgs
, ...
}:

let

  files = ./static/files;

  authorizedMacs = pkgs.writeText "authorized_macs" (lib.concatMapStringsSep "\n" (mac:
  let
    # MACs are typically delimited with ":", but RFC 3580 expects "-".
    rfc3580Mac = lib.toUpper (builtins.replaceStrings [":"] ["-"] mac);

  in
    ''
      ${rfc3580Mac}
              Reply-Message = "Device with MAC Address %{Calling-Station-Id} authorized for network access"    
    '') config.hacknix.freeradius.users.authorizedMacs);

in
{
  inherit files authorizedMacs;
}
