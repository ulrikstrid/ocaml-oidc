(*
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

(** Validate that sub returned from userinfo is the same as in the id_token *)
let validate ~(jwt : Jose.Jwt.t) userinfo =
  let userinfo_json = Yojson.Safe.from_string userinfo in
  let userinfo_sub =
    Yojson.Safe.Util.member "sub" userinfo_json
    |> Yojson.Safe.Util.to_string_option
  in
  let sub =
    Yojson.Safe.Util.member "sub" jwt.payload |> Yojson.Safe.Util.to_string
  in
  match userinfo_sub with
  | Some s when s = sub -> Ok userinfo
  | Some _s -> Error `Sub_missmatch
  | None -> Error `Missing_sub
