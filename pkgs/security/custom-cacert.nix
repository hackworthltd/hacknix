{ stdenv
, lib
, cacert
, blacklist ? []
, pkgs
, extraCerts ? {}
}:

let

  extraCAs = pkgs.writeText "extraCAs"
  (lib.concatStrings
    (lib.mapAttrsToList
      (caName: caPem:
        ''
          ${caName}
          ${caPem}
        '')
      extraCerts));

in
cacert.overrideAttrs (oldAttrs: {

  installPhase = ''
    mkdir -pv $out/etc/ssl/certs
    cat ca-bundle.crt ${extraCAs} > $out/etc/ssl/certs/ca-bundle.crt
    # install individual certs in unbundled output
    mkdir -pv $unbundled/etc/ssl/certs
    cp -v *.crt $unbundled/etc/ssl/certs
    rm -f $unbundled/etc/ssl/certs/ca-bundle.crt  # not wanted in unbundled
  '';

})
