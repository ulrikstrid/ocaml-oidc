type t = {
  id : string;
  response_types : string list;
  grant_types : string list;
  redirect_uris : string list;
  secret : string option;
  token_endpoint_auth_method : string;
}

type meta = {
  redirect_uris : string list;
  response_types : string list option;
  grant_types : string list option;
  application_type : string option;
  contacts : string list option;
  client_name : string option;
  token_endpoint_auth_method : string option;
  logo_uri : string option;
  client_uri : string option;
  policy_uri : string option;
  tos_uri : string option;
  jwks_uri : string option;
  sector_identifier_uri : string option;
  subject_type : string option;
}
[@@deriving yojson { exn = true }, make]

let meta_to_string c =
  meta_to_yojson c |> Yojson.Safe.Util.to_assoc
  |> List.filter (function _, `Null -> false | _ -> true)
  |> fun l -> `Assoc l |> Yojson.Safe.to_string

type dynamic_response = {
  client_id : string;
  client_secret : string option;
  registration_access_token : string option;
  registration_client_uri : string option;
  client_secret_expires_at : int option;
  client_id_issued_at : int option;
  client_id_expires_at : int option;
  application_type : string option;
}

let dynamic_of_json (json : Yojson.Safe.t) :
    (dynamic_response, [> `Msg of string ]) result =
  CCResult.guard_str (fun () ->
      let module Json = Yojson.Safe.Util in
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
      })
  |> CCResult.map_err (fun e -> `Msg e)

let dynamic_of_string response =
  Yojson.Safe.from_string response |> dynamic_of_json

let of_dynamic_and_meta ~dynamic ~meta =
  {
    id = dynamic.client_id;
    redirect_uris = meta.redirect_uris;
    secret = dynamic.client_secret;
    grant_types =
      CCOpt.get_or meta.grant_types ~default:[ "authorization_code" ];
    response_types = CCOpt.get_or meta.response_types ~default:[ "code" ];
    token_endpoint_auth_method =
      CCOpt.get_or meta.token_endpoint_auth_method ~default:"client_secret_post";
  }
