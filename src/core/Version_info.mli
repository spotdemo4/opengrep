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

val version_semgrep : Semver.t
val major_semgrep : int
val minor_semgrep : int
val patch_semgrep : int
