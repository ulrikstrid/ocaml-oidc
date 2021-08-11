type token_type = Bearer

type t = {
  token_type : token_type;
  scope : string option;
  expires_in : int option;
  ext_exipires_in : int option;
  access_token : string;
  refresh_token : string option;
}

let of_json json =
  let module Json = Yojson.Safe.Util in
  {
    token_type = Bearer;
    (* Only Bearer is supported by OIDC, TODO = return a error if it is not Bearer *)
    scope = json |> Json.member "scope" |> Json.to_string_option;
    expires_in = json |> Json.member "expires_in" |> Json.to_int_option;
    ext_exipires_in =
      json |> Json.member "ext_exipires_in" |> Json.to_int_option;
    access_token = json |> Json.member "access_token" |> Json.to_string;
    refresh_token = json |> Json.member "refresh_token" |> Json.to_string_option;
  }

let of_query query =
  {
    token_type = Bearer;
    (* Only Bearer is supported by OIDC, TODO = return a error if it is not Bearer *)
    scope = Uri.get_query_param query "scope";
    expires_in =
      Uri.get_query_param query "expires_in" |> Option.map int_of_string;
    ext_exipires_in =
      Uri.get_query_param query "ext_exipires_in" |> Option.map int_of_string;
    access_token = Uri.get_query_param query "access_token" |> Option.get;
    refresh_token = Uri.get_query_param query "refresh_token";
  }

let of_string str = Yojson.Safe.from_string str |> of_json
