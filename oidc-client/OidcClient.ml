type client = Register of Oidc.Client.meta | Client of Oidc.Client.t

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
    ~(store : store) ~redirect_uri ~provider_uri ~client :
    (store t, Piaf.Error.t) Lwt_result.t =
  let (module KV) = kv in
  let open Lwt_result.Syntax in
  let open Lwt_result.Infix in
  let* http_client = Piaf.Client.create provider_uri in
  let+ client =
    match client with
    | Client c -> Lwt_result.return c
    | Register client_meta ->
        let* discovery =
          Internal.discover ~kv ~store ~http_client ~provider_uri
        in
        Internal.register ~http_client ~client_meta ~discovery
        >|= fun dynamic ->
        Oidc.Client.of_dynamic_and_meta ~dynamic ~meta:client_meta
  in
  { kv; store; client; http_client; provider_uri; redirect_uri }

let discover t =
  Internal.discover ~kv:t.kv ~store:t.store ~http_client:t.http_client
    ~provider_uri:t.provider_uri

let jwks t =
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
        ("client_secret", t.client.secret |> CCOpt.get_or ~default:"secret");
        ("redirect_uri", t.redirect_uri |> Uri.to_string);
      ]
    |> Uri.query |> Uri.encoded_of_query |> Piaf.Body.of_string
  in
  Piaf.Client.post t.http_client
    ~headers:
      [
        ("Content-Type", "application/x-www-form-urlencoded");
        ("Accept", "application/json");
      ]
    ~body token_path
  >>= fun res -> Piaf.Body.to_string res.body

let register t client_meta =
  discover t
  |> Lwt_result.map (fun discovery ->
         Internal.register ~http_client:t.http_client ~client_meta ~discovery)

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

module Microsoft = struct
  let make (type store)
      ~(kv :
         (module KeyValue.KV with type value = string and type store = store))
      ~(store : store) ~app_id ~tenant_id:_ ~secret ~redirect_uri =
    let provider_uri =
      Uri.of_string "https://login.microsoftonline.com/common/v2.0"
    in
    let client =
      Client
        {
          id = app_id;
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          redirect_uris = [ "https://login.microsoftonline.com/common/v2.0" ];
          secret;
          token_endpoint_auth_method = "client_secret_post";
        }
    in
    make ~kv ~store ~redirect_uri ~provider_uri ~client
end

module KeyValue = KeyValue
