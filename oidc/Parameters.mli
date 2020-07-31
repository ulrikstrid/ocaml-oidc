type display = Page | Popup | Touch | Wap

type prompt = None | Login | Consent | Select_account

type t = {
  response_type : string list;
  client : Client.t;
  redirect_uri : string;
  scope : string list;
  state : string option;
  nonce : string;
  claims : Yojson.Safe.t option;
  max_age : int option;
  display : display option;
  prompt : prompt option;
}

val make :
  ?response_type:string list ->
  ?scope:string list ->
  ?state:string ->
  ?claims:Yojson.Safe.t ->
  ?max_age:int ->
  ?display:display ->
  ?prompt:prompt ->
  Client.t ->
  nonce:string ->
  redirect_uri:Uri.t ->
  t

type parse_state =
  | Invalid of string
  | UnauthorizedClient of Client.t
  | InvalidScope of Client.t
  | InvalidWithClient of Client.t
  | InvalidWithRedirectUri of string
  | Valid of t

val to_query : t -> string

val parse_query : clients:Client.t list -> Uri.t -> parse_state
