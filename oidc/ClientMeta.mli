type t = {
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

val to_string : t -> string
