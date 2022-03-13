(** * Copyright 2022 Ulrik Strid. All rights reserved. * Use of this source code
    is governed by a BSD-style * license that can be found in the LICENSE file. *)

type t =
  [ IDToken.validation_error
  | `Sub_missmatch
  | `Missing_userinfo_endpoint
  | `Missing_access_token ]

let to_string = function
  | `Expired -> "expired"
  | `Iat_in_future -> "Iat in future"
  | `Invalid_nonce -> "Invalid nonce"
  | `Invalid_signature -> "Invalid signature"
  | `Invalid_sub_length -> "Invalid sub length"
  | `Missing_aud -> "Missing aud"
  | `Missing_exp -> "Missing exp"
  | `Missing_iat -> "Missing iat"
  | `Missing_iss -> "Missing iss"
  | `Missing_nonce -> "Missing nonce"
  | `Missing_sub -> "Missing sub"
  | `No_jwk_provided -> "No jwk provided"
  | `Unexpected_nonce -> "Unexpected nonce"
  | `Unsafe -> "unsafe"
  | `Wrong_aud_value aud -> Printf.sprintf "Wrong aud value %s" aud
  | `Wrong_iss_value iss -> Printf.sprintf "Wrong iss value %s" iss
  | `Sub_missmatch -> "Sub not matching"
  | `Missing_userinfo_endpoint -> "Missing userinfo endpoint in discovery"
  | `Missing_access_token -> "No access_token in token response"
  | `Msg s -> s
