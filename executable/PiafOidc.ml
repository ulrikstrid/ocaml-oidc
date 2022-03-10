(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

let to_string_body (res : Piaf.Response.t) = Piaf.Body.to_string res.body
let map_piaf_error e = `Msg (Piaf.Error.to_string e)

let request_descr_to_request Oidc.SimpleClient.{ headers; uri; body; meth } =
  let open Lwt_result.Infix in
  let body = Option.map Piaf.Body.of_string body in
  Piaf.Client.Oneshot.request ~headers ?body ~meth uri
  >>= to_string_body
  |> Lwt_result.map_error map_piaf_error
