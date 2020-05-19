type t = {
  client : Piaf.Client.t;
  base_uri : Uri.t;
  discovery : Oidc.Discover.t;
  redirect_uri : Uri.t;
}

let make ~redirect_uri base_uri : (t, Piaf.Error.t) Lwt_result.t =
  let open Lwt_result.Syntax in
  let open Lwt_result.Infix in
  let* client = Piaf.Client.create base_uri in
  let discovery_path =
    Uri.path base_uri ^ "/.well-known/openid-configuration"
  in
  let+ discovery =
    Piaf.Client.get client discovery_path >>= fun res ->
    Piaf.Body.to_string res.body >|= Oidc.Discover.of_string
  in
  { client; base_uri; discovery; redirect_uri }

let discover t =
  let open Lwt_result.Infix in
  Piaf.Client.get t.client "/.well-known/openid-configuration" >>= fun res ->
  Piaf.Body.to_string res.body >|= Oidc.Discover.of_string

let jwks t =
  let open Lwt_result.Infix in
  let jwks_path = Uri.of_string t.discovery.jwks_uri |> Uri.path in
  Piaf.Client.get t.client jwks_path >>= fun res ->
  Piaf.Body.to_string res.body >|= Jose.Jwks.of_string

let get_token ~(client : Oidc.Client.t) t code =
  let open Lwt_result.Infix in
  let token_path = Uri.of_string t.discovery.token_endpoint |> Uri.path in
  let body =
    Printf.sprintf
      "grant_type=authorization_code&scope=openid&code=%s&client_id=%s&client_secret=%s&redirect_uri=%s"
      code client.id
      (client.secret |> CCOpt.get_or ~default:"secret")
      client.redirect_uri
    |> Piaf.Body.of_string
  in
  Piaf.Client.post t.client
    ~headers:
      [
        ("Content-Type", "application/x-www-form-urlencoded");
        ("Accept", "application/json");
      ]
    ~body token_path
  >>= fun res -> Piaf.Body.to_string res.body

module RegisterClient = RegisterClient
