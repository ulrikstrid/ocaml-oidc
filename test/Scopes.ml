(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

open Helpers

let create_scopes () =
  check_string
    "Create scope parameter"
    "openid"
    ([ `OpenID ] |> Oidc.Scopes.to_scope_parameter)

let parse_parameter () =
  Alcotest.(check @@ list string)
    "Parse scope parameter"
    [ "openid"
    ; "email"
    ; "profile"
    ; "address"
    ; "phone"
    ; "offline_access"
    ; "user:repos"
    ]
    (Oidc.Scopes.of_scope_parameter
       "openid email profile address phone offline_access user:repos"
    |> List.map Oidc.Scopes.to_string)

let tests =
  List.map
    make_test_case
    [ "Create scopes parameter", create_scopes
    ; "Parse scope parameter", parse_parameter
    ]

let suite, _ =
  Junit_alcotest.run_and_report
    ~package:"oidc"
    "Scopes"
    [ "OIDC - scopes", tests ]
