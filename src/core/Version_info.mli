(*
   Manipulation of Opengrep version info.

   The actual Opengrep version is in a generated file of its own.
   Use the Semver library to parse, print, and compare versions.
*)

(* The current Opengrep version (the parsed form of Version.version) *)
val version : Semver.t
val major : int
val minor : int
val patch : int
