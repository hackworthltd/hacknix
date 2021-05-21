final: prev:
let
  gitHubFlakeAttrs = inputName: lockFile:
    let
      lock = builtins.fromJSON (builtins.readFile lockFile);
      inherit (lock.nodes."${inputName}".locked) owner repo rev narHash;
      sha256 = narHash;
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    in
    {
      inherit owner repo rev narHash sha256 url;
    };

  ## Useful for importing whole directories.
  ##
  ## Thanks to dtzWill:
  ## https://github.com/dtzWill/nur-packages/commit/f601a6b024ac93f7ec242e6e3dbbddbdcf24df0b#diff-a013e20924130857c649dd17226282ff

  listDirectory = action: dir:
    let
      list = builtins.readDir dir;
      names = builtins.attrNames list;
      allowedName = baseName: !(
        # From lib/sources.nix, ignore editor backup/swap files
        builtins.match "^\\.sw[a-z]$" baseName != null
        || builtins.match "^\\..*\\.sw[a-z]$" baseName != null
        || # Otherwise it's good
        false
      );
      filteredNames = builtins.filter allowedName names;
    in
    builtins.listToAttrs (
      builtins.map
        (
          name: {
            name = builtins.replaceStrings [ ".nix" ] [ "" ] name;
            value = action (dir + ("/" + name));
          }
        )
        filteredNames
    );
  importDirectory = listDirectory import;
  pathDirectory = listDirectory (d: d);
  mkCallDirectory = callPkgs: listDirectory (p: callPkgs p { });

in
{
  lib = (prev.lib or { }) // {
    sources = (prev.lib.sources or { }) // {
      inherit gitHubFlakeAttrs;

      inherit listDirectory pathDirectory importDirectory mkCallDirectory;
    };
  };
}
