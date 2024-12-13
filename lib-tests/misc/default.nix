{
  stdenv,
  pkgs,
  lib,
  selfPath,
}:
let
  version = "1";
in
stdenv.mkDerivation {
  name = "dln-types-misc-${version}";
  buildInputs = [ pkgs.nix ];
  NIX_PATH = "nixpkgs=${pkgs.path}:nixpkgs-overlays=${selfPath}/nix/overlays";

  buildCommand = ''
    datadir="${pkgs.nix}/share"
    export TEST_ROOT=$(pwd)/test-tmp
    export NIX_BUILD_HOOK=
    export NIX_CONF_DIR=$TEST_ROOT/etc
    export NIX_DB_DIR=$TEST_ROOT/db
    export NIX_LOCALSTATE_DIR=$TEST_ROOT/var
    export NIX_LOG_DIR=$TEST_ROOT/var/log/nix
    export NIX_MANIFESTS_DIR=$TEST_ROOT/var/nix/manifests
    export NIX_STATE_DIR=$TEST_ROOT/var/nix
    export NIX_STORE_DIR=$TEST_ROOT/store
    export PAGER=cat
    cacheDir=$TEST_ROOT/binary-cache

    nix-store --init
    cd ${selfPath}/lib-tests/misc

    nix-instantiate --eval --strict misc.nix
    [[ "$(nix-instantiate --eval --strict misc.nix)" == "[ ]" ]]

    touch $out
  '';

  meta.platforms = pkgs.lib.platforms.all;
}
