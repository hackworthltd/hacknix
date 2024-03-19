final: prev:
let
  # Mozilla recommended strongest modern OpenSSL ciphers list.
  #
  # This is useful for many programs that use OpenSSL, when you want
  # to harden the ciphers that the program will accept.
  #
  # From:
  # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&guideline=5.6
  #
  # Note: the "modern" Mozilla OpenSSL config now recommends simply
  # setting ssl_protocols to TLSv1.3 and leaving ssl_ciphers
  # unspecified, but that might be too aggressive in some cases. In
  # any case, this setting should probably only be used with TLSv1.2.

  sslModernCiphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
in
{
  lib = (prev.lib or { }) // {
    security = (prev.lib.security or { }) // {
      inherit sslModernCiphers;
    };
  };
}
