final: prev:
let
  delete-tweets = prev.callPackage ../pkgs/delete-tweets { };
in
{
  inherit delete-tweets;
}
