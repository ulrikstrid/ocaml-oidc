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
(** OAuth2 Client *)

val make :
  ?secret:string ->
  response_types:string list ->
  grant_types:string list ->
  redirect_uris:Uri.t list ->
  token_endpoint_auth_method:string ->
  string ->
  t
(** Create a {{!t} OAuth2 Client} *)
