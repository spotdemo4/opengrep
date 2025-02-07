open Common

(*************************************************************************)
(* Prelude *)
(*************************************************************************)
(* Temporary module while migrating code to osemgrep to fallback to
 * pysemgrep when osemgrep does not handle yet certain options.
 *)

(*************************************************************************)
(* Types *)
(*************************************************************************)
exception Fallback

(*************************************************************************)
(* Entry point *)
(*************************************************************************)

(* dispatch back to pysemgrep! *)
let pysemgrep (caps : < Cap.exec >) argv =
  Logs.debug (fun m ->
      m "execute pyopengrep: %s"
        (argv |> Array.to_list
        |> List_.map (fun arg -> spf "%S" arg)
        |> String.concat " "));
  (* pysemgrep should be in the PATH, thx to the code in
     ../../../cli/bin/semgrep *)
  match Sys.getenv_opt "_OPENGREP_BINARY" with
  | Some entrypoint ->
    CapUnix.execvp caps#exec entrypoint
      (Array.concat [[|argv.(0)|];
                     [| "--legacy" |];
                     Array.sub argv 1 (Array.length argv - 1)]) 
  | None ->
    CapUnix.execvp caps#exec "pyopengrep" argv
