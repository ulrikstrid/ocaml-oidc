(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

type t = {
  client : Oidc.Client.t;
  provider_uri : Uri.t;
  redirect_uri : Uri.t;
}

let make ~redirect_uri ~provider_uri client =
  { client; redirect_uri; provider_uri }

let discovery_uri t =
  Uri.with_path t.provider_uri "/.well-known/openid-configuration"

type request_descr = {
  body : string option;
  headers : (string * string) list;
  uri : Uri.t;
}

(* Used to request a [Oidc.Token.Response.t] *)
let make_token_request ~code ~discovery t =
  let body =
    Oidc.Token.Request.make ~client:t.client ~grant_type:"authorization_code"
      ~scope:["openid"] ~redirect_uri:t.redirect_uri ~code
    |> Oidc.Token.Request.to_body_string in
  let headers =
    [
      ("Content-Type", "application/x-www-form-urlencoded");
      ("Accept", "application/json");
    ] in
  let headers =
    match t.client.token_endpoint_auth_method with
    | "client_secret_basic" ->
      Oidc.Token.basic_auth ~client_id:t.client.id
        ~secret:(Option.value ~default:"" t.client.secret)
      :: headers
    | _ -> headers in
  let uri = discovery.Oidc.Discover.token_endpoint in
  { body = Some body; headers; uri }

let make_userinfo_request ~token ~(discovery : Oidc.Discover.t) =
  let headers =
    [("Authorization", "Bearer " ^ token); ("Accept", "application/json")] in
  Option.map
    (fun uri -> { headers; uri; body = None })
    discovery.userinfo_endpoint

let get_auth_parameters ?scope ?claims ?nonce ~state t =
  Oidc.Parameters.make ?scope ?claims t.client ?nonce ~state
    ~redirect_uri:t.redirect_uri

let get_auth_uri ?scope ?claims ?nonce ~state ~discovery t =
  let query =
    get_auth_parameters ?scope ?claims ?nonce ~state t
    |> Oidc.Parameters.to_query in
  Uri.add_query_params discovery.Oidc.Discover.authorization_endpoint query
