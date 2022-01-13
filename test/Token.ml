open Helpers

let basic_auth () =
  let client_id = "client_~)]|:" in
  let secret = "secret-+" in
  let _, auth = Oidc.Token.basic_auth ~client_id ~secret in
  check_string "basic auth" "Basic Y2xpZW50X34lMjklNUQlN0MlM0E6c2VjcmV0LSUyQg=="
    auth

let basic_auth_cert () =
  let client_id = "client_DQfJmXKGCDTzBTP01976~)]|:" in
  let secret =
    {|secret_sJivIPTojPdABNRBquJoafBPJIlGKCnbdTLhyWPfloLlKeRuuP0149669022{\$}\|}
  in
  let _, auth = Oidc.Token.basic_auth ~client_id ~secret in
  check_string "basic auth"
    "Basic \
     Y2xpZW50X0RRZkptWEtHQ0RUekJUUDAxOTc2fiUyOSU1RCU3QyUzQTpzZWNyZXRfc0ppdklQVG9qUGRBQk5SQnF1Sm9hZkJQSklsR0tDbmJkVExoeVdQZmxvTGxLZVJ1dVAwMTQ5NjY5MDIyJTdCJTVDJTI0JTdEJTVD"
    auth

let tests =
  List.map make_test_case
    [
      ("Basic auth", basic_auth);
      ("Basic auth from certification", basic_auth_cert);
    ]

let suite, _ =
  Junit_alcotest.run_and_report ~package:"oidc" "Token"
    [("OIDC - Token", tests)]
