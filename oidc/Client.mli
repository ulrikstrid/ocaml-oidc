type t = {
  id : string;
  response_types : string list;
  grant_types : string list;
  redirect_uris : string list;  (** TODO: Use Uri.t list*)
  secret : string option;
  token_endpoint_auth_method : string;
}

(* *)
val make :
  ?secret:string ->
  response_types:string list ->
  grant_types:string list ->
  redirect_uris:string list ->
  token_endpoint_auth_method:string ->
  string ->
  t

type meta = {
  redirect_uris : string list;  (** TODO: use Uri.t *)
  response_types : string list option;  (** TODO: use special respone_type *)
  grant_types : string list option;  (** TODO: use special grant_type *)
  application_type : string option;  (** TODO: use special application_type *)
  contacts : string list option;  (** email addresses *)
  client_name : string option;
  token_endpoint_auth_method : string option;  (** TODO: Only valid strings *)
  logo_uri : string option;  (** TODO: use Uri.t *)
  client_uri : string option;  (** TODO: use Uri.t *)
  policy_uri : string option;  (** TODO: use Uri.t *)
  tos_uri : string option;  (** TODO: use Uri.t *)
  jwks_uri : string option;  (** TODO: use Uri.t *)
  sector_identifier_uri : string option;  (** TODO: use Uri.t *)
  subject_type : string option;
      (** TODO: Use subject_type type; "pairwise" or "public" *)
}
[@@deriving yojson, make]
(**
 [ clientMetadata ] used in registration
 *)

val meta_to_string : meta -> string

type dynamic_response = {
  client_id : string;
  client_secret : string option;
  registration_access_token : string option;
  registration_client_uri : string option;  (** TODO: use Uri.t *)
  client_secret_expires_at : int option;
  client_id_issued_at : int option;  (** seconds from 1970-01-01T0:0:0Z UTC *)
  client_id_expires_at : int option;  (** seconds from 1970-01-01T0:0:0Z UTC *)
  application_type : string option;
}
(**
 The [response] also includes the {! ClientMeta.t }
 *)

val dynamic_of_json :
  Yojson.Safe.t -> (dynamic_response, [> `Msg of string ]) result

val dynamic_of_string : string -> (dynamic_response, [> `Msg of string ]) result

val of_dynamic_and_meta : dynamic:dynamic_response -> meta:meta -> t
