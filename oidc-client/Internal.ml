let to_string_body (res : Piaf.Response.t) = Piaf.Body.to_string res.body

let log_body fmterr body =
  let () = Logs.info (fun m -> m fmterr body) in
  body

let register ~http_client ~client_meta ~(discovery : Oidc.Discover.t) =
  match discovery.registration_endpoint with
  | Some endpoint ->
      let open Lwt_result.Infix in
      let meta_string = Oidc.Client.meta_to_string client_meta in
      let body = Piaf.Body.of_string meta_string in
      let registration_path = Uri.of_string endpoint |> Uri.path in
      Piaf.Client.post http_client ~body registration_path >>= to_string_body
      >>= fun s -> Oidc.Client.dynamic_of_string s |> Lwt.return
  | None -> Lwt_result.fail (`Msg "No_registration_endpoint")

let discover (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~http_client ~provider_uri =
  let open Lwt_result.Infix in
  let (module KV) = kv in
  let save discovery =
    Logs.info (fun m -> m "discovery: %s" discovery);
    KV.set ~store "discovery" discovery |> Lwt_result.ok >|= fun _ -> discovery
  in
  Lwt.bind (KV.get ~store "discovery") (fun result ->
      match result with
      | Ok discovery -> Lwt_result.return discovery
      | Error _ ->
          let discover_path =
            Uri.path provider_uri ^ "/.well-known/openid-configuration"
          in

          Piaf.Client.get http_client discover_path >>= to_string_body >>= save)
  >|= log_body "discovery: %s"
  |> Lwt_result.map Oidc.Discover.of_string

let jwks (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~http_client ~provider_uri =
  let open Lwt_result.Infix in
  let open Lwt_result.Syntax in
  let (module KV) = kv in
  let save jwks =
    KV.set ~store "jwks" jwks |> Lwt_result.ok >|= fun _ -> jwks
  in
  Lwt.bind (KV.get ~store "jwks") (fun result ->
      match result with
      | Ok jwks -> Lwt_result.return jwks
      | Error _ ->
          let* discovery = discover ~kv ~store ~http_client ~provider_uri in
          let jwks_path = Uri.of_string discovery.jwks_uri |> Uri.path in
          Piaf.Client.get http_client jwks_path >>= to_string_body >>= save)
  >|= log_body "JWKS: %s"
  |> Lwt_result.map Jose.Jwks.of_string

let validate_userinfo ~(jwt : Jose.Jwt.t) userinfo =
  let userinfo_json = Yojson.Safe.from_string userinfo in
  let userinfo_sub =
    Yojson.Safe.Util.member "sub" userinfo_json
    |> Yojson.Safe.Util.to_string_option
  in
  let sub =
    Yojson.Safe.Util.member "sub" jwt.payload |> Yojson.Safe.Util.to_string
  in
  match userinfo_sub with
  | Some s when s = sub -> Ok userinfo
  | Some _ -> Error `Sub_missmatch
  | None -> Error `Missing_sub
