(*****************************************************************************)
(* Purpose *)
(*****************************************************************************)
(* Unit tests exercising just the semgrep patterns part *)

open Common

let t = Testo.create

(*****************************************************************************)
(* Simple tests defined inline *)
(*****************************************************************************)
(* TODO:
 *  - we could add unit tests for the range returned by match_sts_sts
 *  - we could add unit tests for the code dealing with equivalences
 *)

let enclosing_context_test_dir = Fpath.v "tests/match-patterns-check"

let enclosing_context_test file lang pattern
    (pred : Core_match.t list -> bool) : unit =
  let program =
    (Parse_target2.just_parse_with_lang
      lang (Fpath.append enclosing_context_test_dir (Fpath.v file)))
    .Parsing_result2.ast
  in
  let pattern =
    Parse_pattern2.parse_pattern None lang pattern
  in
  let rule =
    Mini_rule.({id=Rule_ID.of_string_exn "myrule1";
                pattern;
                inside=false;
                message="msg1";
                metadata=None;
                severity=`Warning;
                langs=[lang];
                pattern_string="test: no need for pattern string";
                fix=None;
                fix_regexp=None})
  in
  let matching_conf = {Match_patterns.track_enclosing_context = true} in
  Match_patterns.check ~hook:(fun _ -> ())
    ~matching_conf
    (Rule_options.default, []) [rule]
    (Fpath.v "some/path", Origin.File (Fpath.v "some/origin"), lang, program)
  |> pred
  |> Alcotest.(check bool)
       (spf "failed test for tracking enclosing context in matching: |%s|" file)
       true
                                                                                                                 
let tests ~any_gen_of_string =
  [
    t "sgrep(generic) features" (fun () ->
        (* spec: pattern string, code string, should_match boolean *)
        let triples =
          [
            (* right now any_gen_of_string use the Python sgrep_spatch_pattern
             * parser so the syntax below must be valid Python code
             *)

            (* ------------ *)
            (* spacing *)
            (* ------------ *)

            (* basic string-match of course *)
            ("foo(1,2)", "foo(1,2)", true);
            ("foo(1,3)", "foo(1,2)", false);
            (* matches even when space or newline differs *)
            ("foo(1,2)", "foo(1,     2)", true);
            ("foo(1,2)", "foo(1,\n                        2)", true);
            (* matches even when have comments in the middle *)
            ("foo(1,2)", "foo(1, #foo\n                       2)", true);
            (* ------------ *)
            (* metavariables *)
            (* ------------ *)

            (* for identifiers *)
            ("import $X", "import Foo", true);
            ("x.$X", "x.foo", true);
            (* for expressions *)
            ("foo($X)", "foo(1)", true);
            ("foo($X)", "foo(1+1)", true);
            (* for lvalues *)
            ("$X.method()", "foo.method()", true);
            ("$X.method()", "foo.bar.method()", true);
            (* "linear" patterns, a la Prolog *)
            ("$X & $X", "(a | b) & (a | b)", true);
            ("foo($X, $X)", "foo(a, a)", true);
            ("foo($X, $X)", "foo(a, b)", false);
            (* metavariable on function name *)
            ("$X(1,2)", "foo(1,2)", true);
            (* metavariable on method call *)
            ("$X.foo()", "Bar.foo()", true);
            (* should not match infix expressions though, even if those
             * are transformed internally in Calls *)
            ("$X(...)", "a+b", false);
            (* metavariable for statements *)
            ("if(True): $S\n", "if(True): return 1\n", true);
            (* metavariable for entity definitions *)
            ("def $X():  return 1\n", "def foo(): return 1\n", true);
            (* metavariable for parameter *)
            ("def foo($A, b):  return 1\n", "def foo(x, b): return 1\n", true);
            (* metavariable string for identifiers *)
            (*     "foo('X');", "foo('a_func');", true; *)
            (* many arguments metavariables *)
            (*      "foo($MANYARGS);", "foo(1,2,3);", true; *)

            (* ------------ *)
            (* '...' *)
            (* ------------ *)

            (* '...' in funcall *)
            ("foo(...)", "foo()", true);
            ("foo(...)", "foo(1)", true);
            ("foo(...)", "foo(1,2)", true);
            ("foo($X,...)", "foo(1,2)", true);
            (* ... also match when there is no additional arguments *)
            ("foo($X,...)", "foo(1)", true);
            ("foo(..., 3, ...)", "foo(1,2,3,4)", true);
            (* ... in more complex expressions *)
            ("strstr(...) == False", "strstr(x)==False", true);
            (* in strings *)
            ("foo(\"...\")", "foo(\"this is a long string\")", true);
            (* "foo(\"...\");", "foo(\"a string\" . \"another string\");", true;*)

            (* for stmts *)
            ( "if True: foo(); ...; bar()\n",
              "if True: foo(); foobar(); bar()\n",
              true );
            (* for parameters *)
            ("def foo(...): ...\n", "def foo(a, b): return a+b\n", true);
            ( "def foo(..., foo=..., ...): ...\n",
              "def foo(a, b, foo = 1, bar = 2): return a+b\n",
              true );
            (*      "class Foo { ... }", "class Foo { int x; }", true; *)
            (* '...' in arrays *)
            (*      "foo($X, array(...));",  "foo(1, array(2, 3));", true; *)

            (* ------------ *)
            (* Misc isomorphisms *)
            (* ------------ *)
            (* flexible keyword argument matching, the order does not matter *)
            ("foo(kwd1=$X, kwd2=$Y)", "foo(kwd2=1, kwd1=3)", true);
            (* regexp matching in strings *)
            ("foo(\"=~/a+/\")", "foo(\"aaaa\")", true);
            ("foo(\"=~/a+/\")", "foo(\"bbbb\")", false)
            (*      "new Foo(...);","new Foo;", true; *);
          ]
        in
        triples
        |> List.iter (fun (spattern, scode, should_match) ->
               try
                 let pattern = any_gen_of_string spattern in
                 let code = any_gen_of_string scode in
                 let lang = Lang.Python in
                 let config = Rule_options.default in
                 let env =
                   Matching_generic.environment_of_any lang config code
                 in
                 let matches_with_env =
                   Match_patterns.match_any_any pattern code env
                 in
                 if should_match then
                   Alcotest.(check bool)
                     (spf "pattern:|%s| should match |%s" spattern scode)
                     true (matches_with_env <> [])
                 else
                   Alcotest.(check bool)
                     (spf "pattern:|%s| should not match |%s" spattern scode)
                     true (matches_with_env =*= [])
               with
               | Parsing.Parse_error ->
                   failwith (spf "problem parsing %s or %s" spattern scode)));
    
    t "tracking enclosing context in matching" (fun () ->

      enclosing_context_test "python/class.py" Lang.Python "i = 5"
       (fun r ->
         match r with
         | {Core_match.enclosure = Some
              Enclosure.([
                 {kind = Func;
                  name = "myFun"; _};
                 {kind = Class;
                  name = "MyClass"; _}]); _} :: _ -> true
         | _ -> false);

      enclosing_context_test "cpp/namespace.cpp" Lang.Cpp "i = 5"
       (fun r ->
         match r with
         | {Core_match.enclosure = Some
              Enclosure.([
                 {kind = Func;
                  name = "fun2"; _};
                 {kind = Func;
                  name = "fun1"; _};
                 {kind = Class;
                  name = "Class1"; _}]); _} :: _ -> true
         | _ -> false))
  ]
