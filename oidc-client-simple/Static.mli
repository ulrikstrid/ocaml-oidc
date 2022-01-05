(*
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

type t = {
  client : Oidc.Client.t;
  provider_uri : Uri.t;  (** The uri where we'll find the provider *)
  redirect_uri : Uri.t;  (** The uri where the provider should return the user *)
}
(** Client with information needed to create calls *)

val make : redirect_uri:Uri.t -> provider_uri:Uri.t -> Oidc.Client.t -> t

(* TODO: Add link to spec *)

val discovery_uri : t -> Uri.t
(** Get the discovery_uri as specified in the OIDC spec *)

val get_auth_uri :
  ?scope:string list ->
  ?claims:Yojson.Safe.t ->
  ?nonce:string ->
  state:string ->
  discovery:Oidc.Discover.t ->
  t ->
  Uri.t
(** Get the uri used for redirecting the user to the provider*)

type request_descr = {
  body : string option;
  headers : (string * string) list;
  uri : Uri.t;
}
(** Request description that can be used by a http client to make the needed call *)

val make_token_request :
  code:string -> discovery:Oidc.Discover.t -> t -> request_descr
(** Creates a {!type:request_descr} for the token request *)

val make_userinfo_request :
  token:string -> discovery:Oidc.Discover.t -> request_descr option
(** Creates a {!type:request_descr} for the userinfo request *)
