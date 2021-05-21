final: prev:
let
  exclusiveOr = x: y: (x && !y) || (!x && y);
in
{
  lib = (prev.lib or { }) // {
    inherit exclusiveOr;
    trivial = (prev.lib.trivial or { }) // {
      inherit exclusiveOr;
    };
  };
}
