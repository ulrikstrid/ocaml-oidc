(** Types and functions to work with the token endpoint *)

type token_type = Bearer

type t = {
  token_type : token_type;
  scope : string option;
  expires_in : int option;
  ext_exipires_in : int option;
  access_token : string option;
  refresh_token : string option;
  id_token : string;
}
(** A token response *)

val of_json : Yojson.Safe.t -> t

val of_string : string -> t

(** {2 Utils} *)

val basic_auth : client_id:string -> secret:string -> string * string
(** Creates a valid Basic auth header from [client_id] and [secret] *)
