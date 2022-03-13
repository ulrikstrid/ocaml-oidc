(*
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

type t =
  [ IDToken.validation_error
  | `Sub_missmatch
  | `Missing_userinfo_endpoint
  | `Missing_access_token ]

let to_string (err : t) =
  match err with
  | #IDToken.validation_error as err -> IDToken.validation_error_to_string err
  | `Sub_missmatch -> "Sub not matching"
  | `Missing_userinfo_endpoint -> "Missing userinfo endpoint in discovery"
  | `Missing_access_token -> "No access_token in token response"

let pp ppf err = Fmt.string ppf (to_string err)
