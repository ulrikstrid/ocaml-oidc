open Utils

type 'store t = {
  kv : (module KeyValue.KV with type value = string and type store = 'store);
  store : 'store;
  client : Oidc.Client.t;
  http_client : Piaf.Client.t;
  provider_uri : Uri.t;
  redirect_uri : Uri.t;
}

let make (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ?(http_client : Piaf.Client.t option) ~redirect_uri
    ~provider_uri ~client : (store t, Piaf.Error.t) Lwt_result.t =
  let (module KV) = kv in
  let open Lwt_result.Infix in
  ( match http_client with
  | Some hc -> Lwt_result.return hc
  | None -> Piaf.Client.create provider_uri )
  >|= fun http_client ->
  { kv; store; client; http_client; provider_uri; redirect_uri }

let discover t =
  Internal.discover ~kv:t.kv ~store:t.store ~http_client:t.http_client
    ~provider_uri:t.provider_uri

let get_jwks t =
  Internal.jwks ~kv:t.kv ~store:t.store ~http_client:t.http_client
    ~provider_uri:t.provider_uri

let get_token ~code t =
  let open Lwt_result.Infix in
  let open Lwt_result.Syntax in
  let* discovery = discover t in
  let token_path = Uri.of_string discovery.token_endpoint |> Uri.path in
  let body =
    Uri.add_query_params' Uri.empty
      [
        ("grant_type", "authorization_code");
        ("scope", "openid");
        ("code", code);
        ("client_id", t.client.id);
        ("client_secret", t.client.secret |> ROpt.get_or ~default:"secret");
        ("redirect_uri", t.redirect_uri |> Uri.to_string);
      ]
    |> Uri.query |> Uri.encoded_of_query |> Piaf.Body.of_string
  in
  let headers =
    [
      ("Content-Type", "application/x-www-form-urlencoded");
      ("Accept", "application/json");
    ]
  in
  let headers =
    match t.client.token_endpoint_auth_method with
    | "client_secret_basic" ->
        Oidc.TokenEndpoint.basic_auth ~client_id:t.client.id
          ~secret:(Option.value ~default:"" t.client.secret)
        :: headers
    | _ -> headers
  in
  Piaf.Client.post t.http_client ~headers ~body token_path
  >>= Internal.to_string_body >|= Oidc.TokenResponse.of_string

let get_and_validate_id_token ?nonce ~code t =
  let open Lwt_result.Syntax in
  let* jwks = get_jwks t |> RPiaf.map_piaf_err in
  let* token_response = get_token ~code t |> RPiaf.map_piaf_err in
  let* discovery = discover t |> RPiaf.map_piaf_err in
  ( match Jose.Jwt.of_string token_response.id_token with
  | Ok jwt -> (
      if jwt.header.alg = `None then
        Oidc.IDToken.validate ?nonce ~client:t.client ~issuer:discovery.issuer
          jwt
        |> Result.map (fun _ -> token_response)
      else
        match Oidc.Jwks.find_jwk ~jwt jwks with
        | Some jwk ->
            Oidc.IDToken.validate ?nonce ~client:t.client
              ~issuer:discovery.issuer ~jwk jwt
            |> Result.map (fun _ -> token_response)
        (* When there is only 1 key in the jwks we can try with that according to the OIDC spec *)
        | None when List.length jwks.keys = 1 ->
            let jwk = List.hd jwks.keys in
            Oidc.IDToken.validate ?nonce ~client:t.client
              ~issuer:discovery.issuer ~jwk jwt
            |> Result.map (fun _ -> token_response)
        | None -> Error (`Msg "Could not find JWK") )
  | Error e -> Error e )
  |> Lwt.return

let get_auth_result ?nonce ~params ~state t =
  match (List.assoc_opt "state" params, List.assoc_opt "code" params) with
  | None, _ -> Error (`Msg "No state returned") |> Lwt.return
  | _, None -> Error (`Msg "No code returned") |> Lwt.return
  | Some returned_state, Some code ->
      if List.hd returned_state <> state then
        Error (`Msg "State doesn't match") |> Lwt.return
      else get_and_validate_id_token ?nonce ~code:(List.hd code) t

let get_auth_parameters ?scope ?claims ~nonce ~state t =
  Oidc.Parameters.make ?scope ?claims t.client ~nonce ~state
    ~redirect_uri:t.redirect_uri

let get_auth_uri ?scope ?claims ~nonce ~state t =
  let query =
    get_auth_parameters ?scope ?claims ~nonce ~state t
    |> Oidc.Parameters.to_query
  in
  discover t
  |> Lwt_result.map (fun (discovery : Oidc.Discover.t) ->
         discovery.authorization_endpoint ^ query)

let get_userinfo ~jwt ~token t =
  let open Lwt_result.Infix in
  let open Lwt_result.Syntax in
  let* discovery = discover t |> RPiaf.map_piaf_err in
  let user_info_path = Uri.of_string discovery.userinfo_endpoint |> Uri.path in
  let userinfo =
    Piaf.Client.get t.http_client
      ~headers:
        [ ("Authorization", "Bearer " ^ token); ("Accept", "application/json") ]
      user_info_path
    >>= Internal.to_string_body |> RPiaf.map_piaf_err
  in
  Lwt_result.bind userinfo (fun userinfo ->
      Internal.validate_userinfo ~jwt userinfo |> Lwt.return)
