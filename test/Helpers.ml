let result_t : [> Oidc.IDToken.validation_error] Alcotest.testable =
  let pp = Oidc.IDToken.pp_validation_error in
  Alcotest.testable pp ( = )

let check_string = Alcotest.(check string)
let check_result_string = Alcotest.(check (result string result_t))
let check_result_bool = Alcotest.(check (result bool result_t))

let check_option_string name expected actual =
  Alcotest.(check (option string)) name (Some expected) actual

let check_int = Alcotest.(check int)
let make_test_case (name, test) = Alcotest.test_case name `Quick test
