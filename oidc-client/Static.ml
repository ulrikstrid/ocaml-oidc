open Utils

type 'store t =
  { kv : (module KeyValue.KV with type value = string and type store = 'store)
  ; store : 'store
  ; client : Oidc.Client.t
  ; http_client : Piaf.Client.t
  ; provider_uri : Uri.t
  ; redirect_uri : Uri.t
  }

let make
      (type store)
      ?(http_client : Piaf.Client.t option)
      ~(kv :
         (module KeyValue.KV with type value = string and type store = store))
      ~(store : store)
      ~redirect_uri
      ~provider_uri
      client : (store t, Piaf.Error.t) Lwt_result.t
  =
  let (module KV) = kv in
  let open Lwt_result.Infix in
  (match http_client with
    | Some hc -> Lwt_result.return hc
    | None -> Piaf.Client.create provider_uri)
  >|= fun http_client ->
  { kv; store; client; http_client; provider_uri; redirect_uri }

let discover t =
  Internal.discover
    ~kv:t.kv
    ~store:t.store
    ~http_client:t.http_client
    ~provider_uri:t.provider_uri

let get_jwks t =
  Internal.jwks
    ~kv:t.kv
    ~store:t.store
    ~http_client:t.http_client
    ~provider_uri:t.provider_uri

let get_token ~code t =
  let open Lwt_result.Infix in
  let open Lwt_result.Syntax in
  let* discovery = discover t in
  let token_path = discovery.token_endpoint |> Uri.path in
  (* TODO: Move this into Oidc.Token *)
  let body =
    Oidc.Token.Request.make
      ~client:t.client
      ~grant_type:"authorization_code"
      ~scope:[ `OpenID ]
      ~redirect_uri:t.redirect_uri
      ~code
    |> Oidc.Token.Request.to_body_string
    |> Piaf.Body.of_string
  in
  let headers =
    [ "Content-Type", "application/x-www-form-urlencoded"
    ; "Accept", "application/json"
    ]
  in
  let headers =
    match t.client.token_endpoint_auth_method with
    | "client_secret_basic" ->
      Oidc.Token.basic_auth
        ~client_id:t.client.id
        ~secret:(Option.value ~default:"" t.client.secret)
      :: headers
    | _ -> headers
  in
  Log.debug (fun m -> m "Getting token with client_id: %s" t.client.id);
  Piaf.Client.post t.http_client ~headers ~body token_path
  >>= Internal.to_string_body
  >>= fun x ->
  Lwt.return
    (Result.map_error (fun x -> `Msg x) (Oidc.Token.Response.of_string x))

let get_and_validate_id_token ?nonce ~code t =
  let open Lwt_result.Syntax in
  let* jwks = get_jwks t |> RPiaf.map_piaf_err in
  let* token_response = get_token ~code t |> RPiaf.map_piaf_err in
  let* discovery = discover t |> RPiaf.map_piaf_err in
  Oidc.Token.Response.validate
    ?nonce
    ~jwks
    ~client:t.client
    ~discovery
    token_response
  |> Lwt.return

let get_auth_result ?nonce ~params ~state t =
  match List.assoc_opt "state" params, List.assoc_opt "code" params with
  | None, _ -> Error (`Msg "No state returned") |> Lwt.return
  | _, None -> Error (`Msg "No code returned") |> Lwt.return
  | Some returned_state, Some code ->
    if List.hd returned_state <> state
    then Error (`Msg "State doesn't match") |> Lwt.return
    else get_and_validate_id_token ?nonce ~code:(List.hd code) t

let get_auth_parameters ?scope ?claims ?nonce ~state t =
  Oidc.Parameters.make
    ?scope
    ?claims
    t.client
    ?nonce
    ~state
    ~redirect_uri:t.redirect_uri

let get_auth_uri ?scope ?claims ?nonce ~state t =
  let query =
    get_auth_parameters ?scope ?claims ?nonce ~state t
    |> Oidc.Parameters.to_query
  in
  discover t
  |> Lwt_result.map (fun (discovery : Oidc.Discover.t) ->
    Uri.add_query_params discovery.authorization_endpoint query)

let get_userinfo ~jwt ~token t =
  let open Lwt_result.Infix in
  let open Lwt_result.Syntax in
  let* discovery = discover t |> RPiaf.map_piaf_err in
  match discovery.userinfo_endpoint |> Option.map Uri.path with
  | Some user_info_path ->
    let userinfo =
      Piaf.Client.get
        t.http_client
        ~headers:
          [ "Authorization", "Bearer " ^ token; "Accept", "application/json" ]
        user_info_path
      >>= Internal.to_string_body
      |> RPiaf.map_piaf_err
    in
    Lwt_result.bind userinfo (fun userinfo ->
      Oidc.Userinfo.validate ~jwt userinfo |> Lwt.return)
  (* TODO: Add a separate error for this *)
  | None -> Lwt_result.fail (`Msg "No userinfo in discovery")
