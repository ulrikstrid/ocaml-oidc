(*
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

(** Simpler interface for creating a oidc client *)

type t =
  { client : Client.t
  ; provider_uri : Uri.t  (** The uri where we'll find the provider *)
  ; redirect_uri : Uri.t
    (** The uri where the provider should return the user *)
}
(** Client with information needed to create calls *)

val make :
   ?secret:string
  -> ?response_types:string list
  -> ?grant_types:string list
  -> ?token_endpoint_auth_method:string
  -> redirect_uri:Uri.t
  -> provider_uri:Uri.t
  -> string
  -> t
(** Create a simple client, it creates a {{!type:Client.t} oidc client} with
    some optional defaults.

    Defaults:
    - [response_types] - [["code"]]
    - [grant_types] - [[]]
    - [token_endpoint_auth_method] - [["client_secret_post"]] *)

(** {2 URI builders} *)

val discovery_uri : t -> Uri.t
(** Get the discovery_uri as specified in the
    {{:https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig}
     OIDC spec} *)

val make_auth_uri :
   ?scope:Scopes.t list
  -> ?claims:Yojson.Safe.t
  -> ?nonce:string
  -> state:string
  -> discovery:Discover.t
  -> t
  -> Uri.t
(** Builds the uri used for redirecting the user to the provider

- [scope] example input: [["openid"; "email"; "profile"]]
    - [nonce] should be validated when the user comes back to make sure they
      were not hijacked
    - [state] will be returend by the provider and can be used to remember where
      to redirect the user after successful login *)

(** {2 Request builders}*)

type meth =
  [ `POST
  | `GET
  | `CONNECT
  | `DELETE
  | `HEAD
  | `PUT
  | `TRACE
  | `OPTIONS
  | `Other of string
  ]

type request_descr =
  { body : string option
  ; headers : (string * string) list
  ; uri : Uri.t
  ; meth : meth
}
(** Request description that can be used by a http client to make the needed
    call *)

val make_token_request :
   code:string
  -> discovery:Discover.t
  -> t
  -> request_descr
(** Creates a {!type:request_descr} for the token request *)

val make_refresh_token_request :
   refresh_token:string
  -> discovery:Discover.t
  -> t
  -> request_descr
(** Creates a {!type:request_descr} for the refresh token request *)

val make_userinfo_request :
   token:Token.Response.t
  -> discovery:Discover.t
  -> (request_descr, [> Error.t ]) result
(** Creates a {!type:request_descr} for the userinfo request *)

val valid_token_of_string :
   ?clock_tolerance:int
  -> ?nonce:string
  -> jwks:Jose.Jwks.t
  -> discovery:Discover.t
  -> t
  -> string
  -> (Token.Response.t, [> `Msg of string | IDToken.validation_error ]) result
(** Will parse the string and validate the token

    [clock_tolerance] is used to allow a difference between the providers and
    clients clock *)

val valid_userinfo_of_string :
   token_response:Token.Response.t
  -> string
  -> ( string
       , [> `Missing_sub
    | `Sub_missmatch
    | `Not_json
    | `Not_supported
         | `Msg of string
         ] )
  result

(** {2 Example - Google}

    This example is written as if your http client is synchronos since we don't
    have a [Lwt] or [Async] dependency in the core. For a more complete example
    look in the [executable] folder.

    {3 Server start}

We have to do some things when the server starts to prepare

{[
let secret = Sys.getenv "OIDC_SECRET"
let client_id = Sys.getenv "OIDC_CLIENT_ID"
let provider_uri = Uri.of_string "https://accounts.google.com"
let redirect_uri = Uri.of_string "http://localhost:8080/auth/callback"

      (* Create a client, it will create a oidc client under the hood and
         inherits parameters from there *)
      let simple_client =
        Oidc.SimpleClient.make ~redirect_uri ~provider_uri ~secret client_id

let discovery =
  let uri = Oidc.SimpleClient.discovery_uri simple_client in
  let discovery_string = HttpClient.get uri in
  Oidc.Discover.of_string discovery_string

let jwks =
  let uri = discovery.jwks_uri in
  let jwks_string = HttpClient.get uri in
  Jose.Jwks.of_string jwks_string
]}

{3 Authenitcation route}

    When the user is supposed to login you create the URI and redirect the user
    to the provider.

{[
      let uri =
        Oidc.SimpleClient.make_auth_uri
          ~scope:[ `OpenID; `Email; `Profile ]
          ~state:"state"
          ~discovery
          client
      in
  HttpServer.redirect uri
]}

{3 Callback route}

    When the user returns from the provider we have to fetch the tokens and do
    some validation and (optionally) get the userinfo.

{[
let code = HttpServer.get_query "code" request in
let state = HttpServer.get_query "state" request in

let token_response =
  (* Get a request_descr *)
  let token_request = Oidc.SimpleClient.make_token_request ~code ~discovery client in
  HttpClient.request token_request
  |> Oidc.SimpleClient.valid_token_of_string ~jwks ~discovery client in
in

(* You don't need to get the userinfo, but it can be useful since the id_token doesn't have to include all the information *)
let userinfo =
  (* Get a request_descr *)
  let userinfo_request = Oidc.SimpleClient.make_userinfo_request ~token:validated_token ~discovery in
  HttpClient.request userinfo_request
  |> Oidc.Userinfo.validate ~jwt:token_response_id_token
in

match (validated_token, userinfo) with
| Ok tokens, Ok userinfo ->
  let id_token = tokens.id_token in
  (* Theoretically we're not sure we'll have a access_token... *)
  let access_token =
    Option.value ~default:"no access_token" tokens.access_token
  in
  (* Same as access_token *)
  let refresh_token =
    Option.value ~default:"no refresh_token" tokens.refresh_token
  in

  (* Save the values in session for later retrieval *)
  let () = HttpServer.put_session "id_token" id_token request in
  let () = HttpServer.put_session "access_token" access_token request in
  let () = HttpServer.put_session "refresh_token" refresh_token request in
  let () = HttpServer.put_session "userinfo" userinfo request in

  HttServer.respond id_token
| Error e -> HttpServer.respond @@ Oidc.Error.to_string e
    ]} *)
