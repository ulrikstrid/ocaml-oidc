(** Types and functions to work with clients *)

(** {2 Standard client} *)

type t = {
  id : string;
  response_types : string list;
  grant_types : string list;
  redirect_uris : Uri.t list;
  secret : string option;
  token_endpoint_auth_method : string;
}
(** OIDC Client *)

val make :
  ?secret:string ->
  response_types:string list ->
  grant_types:string list ->
  redirect_uris:Uri.t list ->
  token_endpoint_auth_method:string ->
  string ->
  t
(** Create a {{!t} OIDC Client} *)

(** {2 Dynamic registration} *)

type meta = {
  redirect_uris : Uri.t list;
  response_types : string list option;  (** TODO: use special response_type *)
  grant_types : string list option;  (** TODO: use special grant_type *)
  application_type : string option;  (** TODO: use special application_type *)
  contacts : string list option;  (** email addresses *)
  client_name : string option;
  token_endpoint_auth_method : string option;  (** TODO: Only valid strings *)
  logo_uri : Uri.t option;
  client_uri : Uri.t option;
  policy_uri : Uri.t option;
  tos_uri : Uri.t option;
  jwks_uri : Uri.t option;
  sector_identifier_uri : Uri.t option;
  subject_type : string option;
      (** TODO: Use subject_type type; "pairwise" or "public" *)
  id_token_signed_response_alg : Jose.Jwa.alg option;
}
(** Metadata used in registration of dynamic clients *)

val make_meta :
  ?response_types:string list ->
  ?grant_types:string list ->
  ?application_type:string ->
  ?contacts:string list ->
  ?client_name:string ->
  ?token_endpoint_auth_method:string ->
  ?logo_uri:Uri.t ->
  ?client_uri:Uri.t ->
  ?policy_uri:Uri.t ->
  ?tos_uri:Uri.t ->
  ?jwks_uri:Uri.t ->
  ?sector_identifier_uri:Uri.t ->
  ?subject_type:string ->
  ?id_token_signed_response_alg:Jose.Jwa.alg ->
  redirect_uris:Uri.t list ->
  unit ->
  meta

val meta_to_json : meta -> Yojson.Safe.t
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
(** The actual response response should also include the {{!meta} metadata} *)

val dynamic_is_expired : dynamic_response -> bool
(** This is useful to know if you have to re-register your client *)

val dynamic_of_json :
  Yojson.Safe.t -> (dynamic_response, [> `Msg of string]) result

val dynamic_of_string : string -> (dynamic_response, [> `Msg of string]) result

val of_dynamic_and_meta : dynamic:dynamic_response -> meta:meta -> t
(** Createa a {{!t} OIDC Client} from {!dynamic} and {!meta} *)
