(** Parsing and creating the discovery document *)

type t = {
  authorization_endpoint : string;
  token_endpoint : string;
  jwks_uri : string;
  userinfo_endpoint : string;
  issuer : string;
  registration_endpoint : string option;
}
(** {i The discovery type can include much more than the type currently includes. Feel free to open a PR adding anything you need } *)

val of_json : Yojson.Safe.t -> t
(** {i This might change to return a result in the future} *)

val of_string : string -> t
(** {i This might change to return a result in the future} *)
