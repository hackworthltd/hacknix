final: prev:
let
  ## PEM files corresponding to the pre-configured RFC 7919 DH groups
  ## defined in our lib.security overlay.

  ffdhe2048Pem = final.writeText "ffdhe2048.pem" final.lib.security.ffdhe2048;
  ffdhe3072Pem = final.writeText "ffdhe3072.pem" final.lib.security.ffdhe3072;
  ffdhe4096Pem = final.writeText "ffdhe4096.pem" final.lib.security.ffdhe4096;
in
{
  inherit ffdhe2048Pem ffdhe3072Pem ffdhe4096Pem;
}
