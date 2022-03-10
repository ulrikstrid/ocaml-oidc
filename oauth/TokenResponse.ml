type token_type = Bearer

type t = {
  token_type : token_type;
  scope : string list;
  expires_in : int option;
  ext_exipires_in : int option;
  access_token : string;
  refresh_token : string option;
}

let of_json json =
  let module Json = Yojson.Safe.Util in
  let scope =
    match Json.member "scope" json with
    | `Null -> []
    | `String scope -> [scope]
    | `List json ->
      (* Some OIDC providers (Twitch for example) return an array of strings
         for scope. *)
      List.map Json.to_string json
    | json ->
      raise
        (Json.Type_error
           ("scope: expected a string or an array of strings", json))
  in
  {
    token_type = Bearer;
    (* Only Bearer is supported by OIDC, TODO = return a error if it is not Bearer *)
    scope;
    expires_in = json |> Json.member "expires_in" |> Json.to_int_option;
    ext_exipires_in =
      json |> Json.member "ext_exipires_in" |> Json.to_int_option;
    access_token = json |> Json.member "access_token" |> Json.to_string;
    refresh_token = json |> Json.member "refresh_token" |> Json.to_string_option;
  }

let of_query query =
  let scope =
    let qp = Uri.get_query_param query "scope" in
    Option.value ~default:[]
      (Option.map (fun qp -> String.split_on_char ' ' qp) qp)
  in
  {
    token_type = Bearer;
    (* Only Bearer is supported by OIDC, TODO = return a error if it is not Bearer *)
    scope;
    expires_in =
      Uri.get_query_param query "expires_in" |> Option.map int_of_string;
    ext_exipires_in =
      Uri.get_query_param query "ext_exipires_in" |> Option.map int_of_string;
    access_token = Uri.get_query_param query "access_token" |> Option.get;
    refresh_token = Uri.get_query_param query "refresh_token";
  }

let of_string str = Yojson.Safe.from_string str |> of_json
