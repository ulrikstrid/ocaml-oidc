(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

(* https://www.rfc-editor.org/rfc/rfc3986#section-2.3
    can also contain "." and "~" but we already have 64 characters
*)
let alphabet =
  Base64.make_alphabet
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

let octets = 96 (* 4 * (96/3) = 128 *)

let base64_encode_cstruct cstruct =
  Base64.encode_string ~alphabet ~pad:false @@ Cstruct.to_string cstruct

module Verifier = struct
  type t = string

  (* https://www.rfc-editor.org/rfc/rfc7636#section-4.1 *)
  let make () = Mirage_crypto_rng.generate octets |> base64_encode_cstruct
  let of_string s = s
end

module Challenge = struct
  (* https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)
  type t =
    | Plain of string
    | S256 of string

  type transformation =
    [ `S256
    | `Plain ]

  (* We MUST create sha256 since we can
     https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)
  let make verifier =
    let s256_challenge_string =
      Mirage_crypto.Hash.SHA256.digest (Cstruct.of_string verifier)
      |> base64_encode_cstruct
    in

    S256 s256_challenge_string

  let of_string ~transformation challenge =
    match transformation with
    | `S256 -> S256 challenge
    | `Plain -> Plain challenge

  (* https://www.rfc-editor.org/rfc/rfc7636#section-4.3 *)
  let to_code_challenge_and_method challenge =
    match challenge with
    | Plain challenge -> (challenge, "plain")
    | S256 challenge -> (challenge, "S256")
end

(* https://www.rfc-editor.org/rfc/rfc7636#section-4.6 *)
let verify (verifier : Verifier.t) (challenge : Challenge.t) =
  match challenge with
  | S256 c ->
    let[@warning "-8"] (Challenge.S256 v) = Challenge.make verifier in
    String.compare v c = 0
  | Plain c -> String.compare verifier c = 0
