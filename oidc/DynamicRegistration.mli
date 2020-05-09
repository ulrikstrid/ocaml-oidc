type response = {
  client_id : string;
  client_secret : string option;
  registration_access_token : string option;
  registration_client_uri : string option;  (** TODO: use Uri.t *)
  client_secret_expires_at : int option;
  client_id_issued_at : int option;  (** seconds from 1970-01-01T0:0:0Z UTC *)
  client_id_expires_at : int option;  (** seconds from 1970-01-01T0:0:0Z UTC *)
  application_type : string option;
}
[@@deriving yojson]
(**
 The [response] also includes the {! ClientMeta.t }
 *)

val response_of_string : string -> (response, string) result
