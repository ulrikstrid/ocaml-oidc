(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

(* https://www.rfc-editor.org/rfc/rfc3986#section-2.3
    can also contain "." and "~" but we already have 64 characters  
*)
let alphabet = Base64.make_alphabet "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

let octets = 96 (* 4 * (96/3) = 128 *)

let base64_encode_cstruct cstruct =
  Base64.encode_string ~alphabet ~pad:false @@ Cstruct.to_string cstruct

type verifier = string

(* https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)
type challenge =
| Plain of string
| S256 of string

type challenge_transformation = [ `S256 | `Plain ]

(* https://www.rfc-editor.org/rfc/rfc7636#section-4.1 *)
let make_code_verifier () =
  Mirage_crypto_rng.generate octets
  |> base64_encode_cstruct

let verifier_of_string s = s
  
(* We MUST create sha256 since we can
  https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)
let make_code_challenge verifier =
  let s256_challenge_string =
    Mirage_crypto.Hash.SHA256.digest (Cstruct.of_string verifier)
    |> base64_encode_cstruct
  in

  S256 s256_challenge_string

let challenge_of_string ~transformation challenge =
  match transformation with
  | `S256 -> S256 challenge
  | `Plain -> Plain challenge

(* https://www.rfc-editor.org/rfc/rfc7636#section-4.3 *)
let challenge_to_code_challange_and_method challenge =
  match challenge with
  | Plain challenge -> (challenge, "plain")
  | S256 challenge -> (challenge, "S256")

(* https://www.rfc-editor.org/rfc/rfc7636#section-4.6 *)
let verify (verifier : verifier) (challenge : challenge) =
  match challenge with
  | S256 c -> 
    let [@warning "-8"] S256 v = make_code_challenge verifier in
    (String.compare v c) = 0
  | Plain c ->
    (String.compare verifier c) = 0