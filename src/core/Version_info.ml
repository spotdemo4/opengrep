(*
   Details about the Semgrep version for this build.

   The Semgrep version string comes from a generated file.

   TODO: merge with Version.ml instead?
*)

let version =
  match Semver.of_string Version.version with
  | Some x -> x
  | None ->
      failwith
        ("Cannot parse the Opengrep version string found in the Version module: "
       ^ Version.version)

let major, minor, patch = version

let version_semgrep =
  match Semver.of_string Version.version_semgrep with
  | Some x -> x
  | None ->
      failwith
        ("Cannot parse the Opengrep's compatibility version string \
          found in the Version module: "
       ^ Version.version_semgrep)

let major_semgrep, minor_semgrep, patch_semgrep = version_semgrep
