final: prev:
let
  dhess = "Drew Hess <dhess-src@hackworthltd.com>";
in
{
  lib = (prev.lib or { }) // {
    maintainers = (prev.lib.maintainers or { }) // {
      inherit dhess;
    };
  };
}
