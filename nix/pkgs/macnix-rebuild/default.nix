{ stdenv
, buildEnv
, writeShellScriptBin
, lib
}:
let
  version = "1.0";
  name = "macnix-rebuild-${version}";
  script = (writeShellScriptBin "macnix-rebuild"
    (builtins.readFile ./macnix-rebuild.sh))
  // {
    meta.platforms = lib.platforms.darwin;
  };
in
script
