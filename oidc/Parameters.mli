(** Auth parameters *)

type display =
  [ `Page
  | `Popup
  | `Touch
  | `Wap ]

type prompt =
  [ `None
  | `Login
  | `Consent
  | `Select_account ]

type t = {
  response_type : string list;
  client_id : string;
  redirect_uri : Uri.t;
  scope : Scopes.t list;
  state : string option;
  nonce : string option;
  claims : Yojson.Safe.t option;
  max_age : int option;
  display : display option;
  prompt : prompt option;
}

type error =
  [ `Unauthorized_client of Client.t
  | `Missing_client
  | `Invalid_scope of string list
  | `Invalid_redirect_uri of string
  | `Missing_parameter of string
  | `Invalid_display of string
  | `Invalid_prompt of string
  | `Invalid_parameters ]
(** Possible states when parsing the query *)

val make :
  ?response_type:string list ->
  ?scope:Scopes.t list ->
  ?state:string ->
  ?claims:Yojson.Safe.t ->
  ?max_age:int ->
  ?display:display ->
  ?prompt:prompt ->
  ?nonce:string ->
  redirect_uri:Uri.t ->
  client_id:string ->
  unit ->
  t

val to_query : t -> (string * string list) list
(** Used when starting a authentication *)

val to_yojson : t -> Yojson.Safe.t
val of_yojson : Yojson.Safe.t -> (t, [> error]) result

(** {2 Parsing in the provider} *)

val parse_query : allowed_redirect_uris:string list -> Uri.t -> (t, [> error]) result

