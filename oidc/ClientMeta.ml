type t = {
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
[@@deriving yojson, make]

let to_string c =
  to_yojson c |> Yojson.Safe.Util.to_assoc
  |> List.filter (function _, `Null -> false | _ -> true)
  |> fun l -> `Assoc l |> Yojson.Safe.to_string
