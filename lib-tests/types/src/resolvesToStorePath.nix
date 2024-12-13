# to run these tests:
# nix-instantiate --eval --strict resolvesToStorePath.nix
# if the resulting list is empty, all tests passed

with import <nixpkgs> { };
let
  inherit (pkgs.lib)
    all
    any
    id
    isStorePath
    runTests
    ;
  inherit (pkgs.lib.secrets) resolvesToStorePath secretPath;

  allTrue = all id;
  anyTrue = any id;
in
runTests rec {

  storePaths = [
    ./resolvesToStorePath.nix
    ../default.nix
    pkgs.python3
    "${builtins.storeDir}/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11/bin/python"
    "${builtins.storeDir}/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11/bin/"
    "${builtins.storeDir}/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11/bin"
    "${builtins.storeDir}/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11/"
    "${builtins.storeDir}/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11"
  ];

  notStorePaths = [
    ""
    "abcd"
    "abcd/efg"
    "abcd/../foo"
    "/home/dhess"
    "/run/keys/foo"
    "./resolvesToStorePath.nix"
    "../default.nix"
    (toString ./resolvesToStorePath.nix)
    (toString ../default.nix)
  ];

  test-resolvesToStorePath = {
    expr = allTrue (map resolvesToStorePath storePaths);
    expected = true;
  };

  test-not-resolvesToStorePath = {
    expr = anyTrue (map resolvesToStorePath notStorePaths);
    expected = false;
  };

  # secretPath utility function uses resolvesToStorePath to check for
  # safe secret paths.

  test-secretPath = {
    expr = secretPath ./resolvesToStorePath.nix == "/illegal-secret-path";
    expected = false;
  };

  test-bad-secretPath = {
    expr = secretPath pkgs.python3 == "/illegal-secret-path";
    expected = true;
  };

}
