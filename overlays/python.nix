self: super:

let

  # A list of "core" Python packages that we want to build for any
  # given release of this overlay.
  coreList = pp: with pp; [
    flake8
    importmagic
    ipython
    jedi
    yapf
  ];  

  python-env = super.python3.buildEnv.override {
    ignoreCollisions = true;
    extraLibs = coreList super.python3Packages;
  };

  delete-tweets = super.callPackage ../pkgs/python/delete-tweets {};

in
{
  inherit delete-tweets;
  inherit python-env;
}
