type token_type = Bearer

type t = {
  token_type : token_type;
  scope : string list;
  expires_in : int option;
  ext_exipires_in : int option;
  access_token : string option;
  refresh_token : string option;
  id_token : string;
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
    access_token = json |> Json.member "access_token" |> Json.to_string_option;
    refresh_token = json |> Json.member "refresh_token" |> Json.to_string_option;
    id_token = json |> Json.member "id_token" |> Json.to_string;
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
    access_token = Uri.get_query_param query "access_token";
    refresh_token = Uri.get_query_param query "refresh_token";
    id_token = Uri.get_query_param query "id_token" |> Option.get;
  }

let of_string str = Yojson.Safe.from_string str |> of_json

let validate ?clock_tolerance ?nonce ~jwks ~(client : Client.t)
    ~(discovery : Discover.t) t =
  match Jose.Jwt.of_string t.id_token with
  | Ok jwt -> (
    if jwt.header.alg = `None then
      IDToken.validate ?clock_tolerance ?nonce ~client ~issuer:discovery.issuer
        jwt
      |> Result.map (fun _ -> t)
    else
      match Jwks.find_jwk ~jwt jwks with
      | Some jwk ->
        IDToken.validate ?clock_tolerance ?nonce ~client
          ~issuer:discovery.issuer ~jwk jwt
        |> Result.map (fun _ -> t)
      (* When there is only 1 key in the jwks we can try with that according to the OIDC spec *)
      | None when List.length jwks.keys = 1 ->
        let jwk = List.hd jwks.keys in
        IDToken.validate ?clock_tolerance ?nonce ~client
          ~issuer:discovery.issuer ~jwk jwt
        |> Result.map (fun _ -> t)
      | None -> Error (`Msg "Could not find JWK"))
  | Error e -> Error e
