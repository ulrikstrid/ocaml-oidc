type client = Register of Oidc.Client.meta | Client of Oidc.Client.t

type t = {
  client : Oidc.Client.t;
  http_client : Piaf.Client.t;
  provider_uri : Uri.t;
  discovery : Oidc.Discover.t;
  redirect_uri : Uri.t;
}

let register ~http_client ~client_meta ~(discovery : Oidc.Discover.t) =
  match discovery.registration_endpoint with
  | Some endpoint ->
      let open Lwt_result.Infix in
      let meta_string = Oidc.Client.meta_to_string client_meta in
      let body = Piaf.Body.of_string meta_string in
      let registration_path = Uri.of_string endpoint |> Uri.path in
      Piaf.Client.post http_client ~body registration_path >>= fun res ->
      Piaf.Body.to_string res.body >>= fun s ->
      Oidc.Client.dynamic_of_string s |> Lwt.return
  | None -> Lwt_result.fail (`Msg "No_registration_endpoint")

let make ~redirect_uri ~provider_uri ~client : (t, Piaf.Error.t) Lwt_result.t =
  let open Lwt_result.Syntax in
  let open Lwt_result.Infix in
  let* http_client = Piaf.Client.create provider_uri in
  let discovery_path =
    Uri.path provider_uri ^ "/.well-known/openid-configuration"
  in
  let* discovery =
    Piaf.Client.get http_client discovery_path >>= fun res ->
    Piaf.Body.to_string res.body >|= Oidc.Discover.of_string
  in
  let+ client =
    match client with
    | Client c -> Lwt_result.return c
    | Register client_meta ->
        register ~http_client ~client_meta ~discovery >|= fun dynamic ->
        Oidc.Client.of_dynamic_and_meta ~dynamic ~meta:client_meta
  in
  { client; http_client; provider_uri; discovery; redirect_uri }

let discover t =
  let open Lwt_result.Infix in
  Piaf.Client.get t.http_client "/.well-known/openid-configuration"
  >>= fun res -> Piaf.Body.to_string res.body >|= Oidc.Discover.of_string

let jwks t =
  let open Lwt_result.Infix in
  let jwks_path = Uri.of_string t.discovery.jwks_uri |> Uri.path in
  Piaf.Client.get t.http_client jwks_path >>= fun res ->
  Piaf.Body.to_string res.body >|= fun jwks ->
  print_endline jwks;
  Jose.Jwks.of_string jwks

let get_token ~code t =
  let open Lwt_result.Infix in
  let token_path = Uri.of_string t.discovery.token_endpoint |> Uri.path in
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
  register ~http_client:t.http_client ~client_meta ~discovery:t.discovery

let get_auth_parameters ?scope ?claims ~nonce ~state t =
  Oidc.Parameters.make ?scope ?claims t.client ~nonce ~state
    ~redirect_uri:t.redirect_uri

let get_auth_uri ?scope ?claims ~nonce ~state t =
  let query =
    get_auth_parameters ?scope ?claims ~nonce ~state t
    |> Oidc.Parameters.to_query
  in
  t.discovery.authorization_endpoint ^ query

module Microsoft = struct
  let make ~app_id ~tenant_id:_ ~secret ~redirect_uri =
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
    make ~redirect_uri ~provider_uri ~client
end
