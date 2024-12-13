## Securely dealing with secrets; i.e., preventing them from
## entering the Nix store.

final: prev:
let
  # True if the argument is a path (or a string, when treated as a
  # path) that resolves to a Nix store path; i.e., the path begins
  # with `/nix/store`. It is an error to call this on anything that
  # doesn't evaluate in a string context.
  resolvesToStorePath =
    x:
    let
      stringContext = "${x}";
    in
    builtins.substring 0 1 stringContext == "/" && final.lib.hasPrefix builtins.storeDir stringContext;

  ## These are all predicated on the behavior of the `secretPath`
  ## function, which takes a path and either return the path, if it
  ## doesn't resolve to a store path; or "/illegal-secret-path", if it
  ## does.

  secretPath =
    path:
    let
      safePath = toString path;
    in
    if resolvesToStorePath safePath then "/illegal-secret-path" else safePath;

  secretReadFile = path: builtins.readFile (secretPath path);
  secretFileContents = path: final.lib.fileContents (secretPath path);
in
{
  lib = (prev.lib or { }) // {
    secrets = (prev.lib.secrets or { }) // {
      inherit resolvesToStorePath;
      inherit secretPath secretReadFile secretFileContents;
    };
  };
}
