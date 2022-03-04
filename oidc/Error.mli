(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

type t =
  [ IDToken.validation_error
  | `Sub_missmatch
  | `Missing_userinfo_endpoint
  | `Missing_access_token ]
(** Possible errors *)

val to_string : t -> string
(** Convert error to string *)
