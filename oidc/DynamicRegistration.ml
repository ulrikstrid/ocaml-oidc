type response = {
  client_id : string;
  client_secret : string option;
  registration_access_token : string option;
  registration_client_uri : string option;
  client_secret_expires_at : int option;
  client_id_issued_at : int option;
  client_id_expires_at : int option;
  application_type : string option;
}
[@@deriving yojson]

let of_json json =
  let module Json = Yojson.Safe.Util in
  try
    Ok
      {
        client_id = json |> Json.member "client_id" |> Json.to_string;
        client_secret =
          json |> Json.member "client_secret" |> Json.to_string_option;
        registration_access_token =
          json
          |> Json.member "registration_access_token"
          |> Json.to_string_option;
        registration_client_uri =
          json |> Json.member "registration_client_uri" |> Json.to_string_option;
        client_secret_expires_at =
          json |> Json.member "client_secret_expires_at" |> Json.to_int_option;
        client_id_issued_at =
          json |> Json.member "client_id_issued_at" |> Json.to_int_option;
        client_id_expires_at =
          json |> Json.member "client_id_expires_at" |> Json.to_int_option;
        application_type =
          json |> Json.member "application_type" |> Json.to_string_option;
      }
  with Json.Type_error (e, _) -> Error e

let response_of_string response = Yojson.Safe.from_string response |> of_json
