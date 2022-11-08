(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

open Helpers
open Oidc.Pkce

(* Values from https://www.rfc-editor.org/rfc/rfc7636#appendix-B *)
let code_verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
let code_challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

let create_challenge () =
  let verifier = Verifier.of_string code_verifier in
  let challenge = Challenge.make verifier in
  let challenge_string, _meth =
    Challenge.to_code_challenge_and_method challenge
  in
  check_string "Create code_challenge from code_verifier" code_challenge
    challenge_string

let verify_challenge () =
  let verifier = Verifier.of_string code_verifier in
  let challenge = Challenge.of_string ~transformation:`S256 code_challenge in
  Alcotest.(check bool)
    "Verify challenge and verifier" true
    (verify verifier challenge)

let tests =
  List.map make_test_case
    [
      ("Creates the same challenge", create_challenge);
      ("Verify challenge and verifier", verify_challenge);
    ]

let suite, _ =
  Junit_alcotest.run_and_report ~package:"oidc" "pkce" [("OIDC - pkce", tests)]
