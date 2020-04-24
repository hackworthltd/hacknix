# XXX dhess TODO - make the platform darwin only.

{ stdenv, buildEnv, writeShellScriptBin }:

let

  version = "1.0";
  name = "macnix-rebuild-${version}";
  script = writeShellScriptBin "macnix-rebuild"
    (builtins.readFile ./macnix-rebuild.sh);

in script
