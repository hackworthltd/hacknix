{ stdenv
, pkgs
, lib
}:
let
  version = "1";

  ffdhe2048Sha512 = "d701f16489970432057280130dcd11f7d623daa0f76cc78f7b74bb487706e6b5a013e410e29d7ba5b951b46dfbc661ff13ae90363f8cb4209b27d2eee339a7a2";

  ffdhe3072Sha512 = "0c8db8fc0ef144273438d8ba6a363a240964a7e77a55739bae50f8f86994c6b3bd5d05935a3d247e84d6821b9761c014750897a16ed653c19944b58f4a9aca45";

  ffdhe4096Sha512 = "716a462baecb43520fb1ba6f15d288ba8df4d612bf9d450474b4a1c745b64be01806e5ca4fb2151395fd4412a98831b77ea8dfd389fe54a9c768d170b9565a25";
in
stdenv.mkDerivation {
  name = "dln-security-ffdhe-test-${version}";
  buildInputs = [
    pkgs.coreutils
  ];

  buildCommand = ''
    printf "Checking ffdhe2048.pem SHA-512... "
    [[ `cat ${pkgs.ffdhe2048Pem} | sha512sum` == "${ffdhe2048Sha512}  -" ]] || (echo "mismatch" && exit 1)
    echo "ok"

    printf "Checking ffdhe3072.pem SHA-512... "
    [[ `cat ${pkgs.ffdhe3072Pem} | sha512sum` == "${ffdhe3072Sha512}  -" ]] || (echo "mismatch" && exit 1)
    echo "ok"

    printf "Checking ffdhe4096.pem SHA-512... "
    [[ `cat ${pkgs.ffdhe4096Pem} | sha512sum` == "${ffdhe4096Sha512}  -" ]] || (echo "mismatch" && exit 1)
    echo "ok"

    touch $out
  '';

  meta.platforms = pkgs.lib.platforms.all;
}
