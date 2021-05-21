final: prev:
let
  shortRev = builtins.substring 0 7;
in
{
  lib = (prev.lib or { }) // {
    misc = (prev.lib.misc or { }) // {
      inherit shortRev;
    };
  };
}
