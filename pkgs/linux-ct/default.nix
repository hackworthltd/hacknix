{ stdenv
, buildPackages
, fetchFromGitHub
, perl
, buildLinux
, modDirVersionArg ? null
, ...
} @ args:

with stdenv.lib;

buildLinux
  (args // rec {
    version = "5.4.35";

    # modDirVersion needs to be x.y.z, will automatically add .0 if needed
    modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) else modDirVersionArg;

    # branchVersion needs to be x.y
    extraMeta.branch = versions.majorMinor version;

    src = fetchFromGitHub {
      owner = "greearb";
      repo = "linux-ct-5.4";
      rev = "869131a3a97fdd664443428ead9fd48f393d4a9f";
      sha256 = "1b696wq0yalvi9a6gih56nhympffq6bww8m3m909s4r7994vq05g";
    };
  } // (args.argsOverride or { }))
