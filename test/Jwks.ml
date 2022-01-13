open Helpers

let () = Mirage_crypto_rng_unix.initialize ()
let rsa = Mirage_crypto_pk.Rsa.generate ~bits:1024 ()
let jwk = Jose.Jwk.make_priv_rsa rsa

let jwks : Jose.Jwks.t =
  { keys = [Jose.Jwk.make_pub_rsa (rsa |> Mirage_crypto_pk.Rsa.pub_of_priv)] }

let header = Jose.Header.make_header jwk

let jwt_with_kid =
  Jose.Jwt.sign jwk ~header ~payload:(`Assoc [("sub", `String "sub")])
  |> Result.get_ok

let jwt_without_kid =
  Jose.Jwt.sign jwk ~header:{ header with kid = None }
    ~payload:(`Assoc [("sub", `String "sub")])
  |> Result.get_ok

let find_jwk_with_kid () =
  let found_jwk = Oidc.Jwks.find_jwk ~jwt:jwt_with_kid jwks in
  match found_jwk with
  | Some found_jwk ->
    check_result_string "thumbprint"
      (Jose.Jwk.get_thumbprint `SHA1 jwk)
      (Jose.Jwk.get_thumbprint `SHA1 found_jwk)
  | None ->
    print_endline "Did not find jwk";
    raise Not_found

let find_jwk_without_kid () =
  let found_jwk = Oidc.Jwks.find_jwk ~jwt:jwt_without_kid jwks in
  match found_jwk with
  | Some found_jwk ->
    check_result_string "thumbprint"
      (Jose.Jwk.get_thumbprint `SHA1 jwk)
      (Jose.Jwk.get_thumbprint `SHA1 found_jwk)
  | None ->
    print_endline "Did not find jwk";
    raise Not_found

let tests =
  List.map make_test_case
    [("With kid", find_jwk_with_kid); ("Without kid", find_jwk_without_kid)]

let suite, _ =
  Junit_alcotest.run_and_report ~package:"oidc" "Jwks" [("OIDC - JWKs", tests)]
