(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

type t = {
  client : Client.t;
  provider_uri : Uri.t;
  redirect_uri : Uri.t;
}

let make ?secret ?(response_types = ["code"]) ?(grant_types = [])
    ?(token_endpoint_auth_method = "client_secret_post") ~redirect_uri
    ~provider_uri client_id =
  let client =
    Client.make ?secret ~response_types ~grant_types
      ~redirect_uris:[redirect_uri] ~token_endpoint_auth_method client_id
  in
  { client; redirect_uri; provider_uri }

let discovery_uri t =
  let base_path = Uri.path t.provider_uri in
  Uri.with_path t.provider_uri (base_path ^ "/.well-known/openid-configuration")

type meth =
  [ `POST
  | `GET
  | `CONNECT
  | `DELETE
  | `HEAD
  | `PUT
  | `TRACE
  | `OPTIONS
  | `Other of string ]

type request_descr = {
  body : string option;
  headers : (string * string) list;
  uri : Uri.t;
  meth : meth;
}

(* Used to request a [Token.Response.t] *)
let make_token_request ~code ~discovery t =
  let body =
    Token.Request.make ~client:t.client ~grant_type:"authorization_code"
      ~scope:[`OpenID] ~redirect_uri:t.redirect_uri ~code
    |> Token.Request.to_body_string
  in
  let headers =
    [
      ("Content-Type", "application/x-www-form-urlencoded");
      ("Accept", "application/json");
    ]
  in
  let headers =
    match t.client.token_endpoint_auth_method with
    | "client_secret_basic" ->
      Token.basic_auth ~client_id:t.client.id
        ~secret:(Option.value ~default:"" t.client.secret)
      :: headers
    | _ -> headers
  in
  let uri = discovery.Discover.token_endpoint in
  { body = Some body; headers; uri; meth = `POST }

let make_userinfo_request ~(token : Token.Response.t) ~(discovery : Discover.t)
    =
  match (discovery.userinfo_endpoint, token) with
  | Some userinfo_endpoint, { access_token = Some access_token; _ } ->
    let headers =
      [
        ("Authorization", "Bearer " ^ access_token);
        ("Accept", "application/json");
      ]
    in
    let request_descr : request_descr =
      { headers; uri = userinfo_endpoint; body = None; meth = `GET }
    in
    (Ok request_descr : (request_descr, [> Error.t]) result)
  | Some _, { access_token = None; _ } -> Error `Missing_access_token
  | None, _ -> Error `Missing_userinfo_endpoint

let get_auth_parameters ?scope ?claims ?nonce ~state t =
  Parameters.make ?scope ?claims ?nonce ~state ~redirect_uri:t.redirect_uri
    ~client_id:t.client.id ()

let make_auth_uri ?scope ?claims ?nonce ~state ~discovery t =
  let query =
    get_auth_parameters ?scope ?claims ?nonce ~state t |> Parameters.to_query
  in
  Uri.add_query_params discovery.Discover.authorization_endpoint query

let valid_token_of_string ?clock_tolerance ~jwks ~discovery t body =
  let ret = Token.Response.of_string body in
  match ret with
  | Ok ret ->
    Token.Response.validate ?clock_tolerance ~jwks ~discovery ~client:t.client
      ret
  | e -> e

let valid_userinfo_of_string ~(token_response : Token.Response.t) userinfo =
  match Jose.Jwt.unsafe_of_string (Option.get token_response.id_token) with
  | Ok jwt -> Userinfo.validate ~jwt userinfo
  | Error e -> Error e
