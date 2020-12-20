{ stdenv
, buildPackages
, perl
, buildLinux
, fetchFromGitHub
, modDirVersionArg ? null
, ...
} @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "5.4.52-ct";

  src = fetchFromGitHub {
    owner = "greearb";
    repo = "linux-ct-5.4";
    rev = "d8f05242d73ee1fda0f1585480eb70e14acd39ca";
    sha256 = "11b8mzi9gcy2wy1mqasshb4ajgaha4fpwn43bbx30c36k7q2wh2r";
  };

  features = {
    # Not working in this kernel version.
    iwlwifi = false;
  };

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;
} // (args.argsOverride or { }))
