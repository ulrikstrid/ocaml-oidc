open Utils

let to_string_body (res : Piaf.Response.t) = Piaf.Body.to_string res.body

let read_registration ~http_client ~client_id ~(discovery : Oidc.Discover.t) =
  match discovery.registration_endpoint with
  | Some endpoint -> (
    let open Lwt_result.Infix in
    let registration_path = endpoint |> Uri.path in
    let query = Uri.encoded_of_query [("client_id", [client_id])] in
    let uri = registration_path ^ query in
    Piaf.Client.get http_client uri >>= to_string_body >>= fun s ->
    match Oidc.Client.dynamic_of_string s with
    | Ok s -> Lwt_result.return s
    | Error e -> Lwt_result.fail (`Msg e))
  | None -> Lwt_result.fail (`Msg "No_registration_endpoint")

let register (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~http_client ~meta ~(discovery : Oidc.Discover.t) =
  let (module KV) = kv in
  let open Lwt_result.Infix in
  ( KV.get ~store "dynamic_string" >>= fun dynamic_string ->
    Lwt.return
      (match Oidc.Client.dynamic_of_string dynamic_string with
      | Error e -> Error (`Msg e)
      | Ok dynamic ->
        if Oidc.Client.dynamic_is_expired dynamic then Error `Expired_client
        else Ok dynamic) )
  |> fun r ->
  Lwt.bind r (fun x ->
      match (x, discovery.registration_endpoint) with
      | Ok dynamic, _ -> Lwt_result.return dynamic
      | Error _, Some endpoint ->
        let meta_string = Oidc.Client.meta_to_string meta in
        let body = Piaf.Body.of_string meta_string in
        let registration_path = endpoint |> Uri.path in
        ( Piaf.Client.post http_client ~body registration_path >>= to_string_body
        >>= fun dynamic_string ->
          let () = Log.debug (fun m -> m "dynamic string: %s" dynamic_string) in
          let open Lwt.Syntax in
          let+ () = KV.set ~store "dynamic_string" dynamic_string in
          Ok dynamic_string )
        >>= fun s ->
        (match Oidc.Client.dynamic_of_string s with
        | Ok s -> Ok s
        | Error e -> Error (`Msg e))
        |> Lwt.return
      | Error _, None -> Lwt_result.fail (`Msg "No_registration_endpoint"))

let discover (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~http_client ~provider_uri :
    (Oidc.Discover.t, Piaf.Error.t) Lwt_result.t =
  let (module KV) = kv in
  let open Lwt.Syntax in
  let save discovery =
    Log.debug (fun m -> m "discovery: %s" discovery);
    let+ () = KV.set ~store "discovery" discovery in
    discovery
  in
  let* result = KV.get ~store "discovery" in
  let open Lwt_result.Syntax in
  let* discovery =
    match result with
    | Ok discovery -> Lwt_result.return discovery
    | Error _ ->
      let discover_path =
        Uri.path provider_uri ^ "/.well-known/openid-configuration"
      in
      let* response = Piaf.Client.get http_client discover_path in
      let* body = to_string_body response in
      Lwt.bind (save body) (fun body -> Lwt_result.return body)
  in
  Lwt.return
    (Result.map_error (fun x -> `Msg x) (Oidc.Discover.of_string discovery))

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
        let jwks_path = discovery.jwks_uri |> Uri.path in
        Piaf.Client.get http_client jwks_path >>= to_string_body >>= save)
  |> Lwt_result.map Jose.Jwks.of_string

(* TODO: Move to oidc lib *)
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
  | Some s when s = sub ->
    Log.debug (fun m -> m "Userinfo is valid");
    Ok userinfo
  | Some s ->
    Log.debug (fun m -> m "Userinfo has invalid sub, expected %s got %s" sub s);
    Error `Sub_missmatch
  | None ->
    Log.debug (fun m -> m "Userinfo is missing sub");
    Error `Missing_sub
