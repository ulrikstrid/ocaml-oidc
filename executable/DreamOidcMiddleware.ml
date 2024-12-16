let log = Dream.sub_log "dream.oidc"

let redirect_200 url =
  let html =
    Printf.sprintf
      {|<html><head><meta http-equiv="refresh" content="0;URL='%s'"/></head><body><p>Moved to <a href="%s">%s</a>.</p></body></html>|}
      url
      url
      url
  in
  Dream.html html

let auth_handler ~discovery ~client ~scope request =
  let uri =
    Oidc.SimpleClient.make_auth_uri ~scope ~state:"state" ~discovery client
  in
  Dream.redirect request @@ Uri.to_string uri

let callback_handler ~redirect_to ~discovery ~jwks ~client request =
  let code = Dream.query request "code" in
  let _state = Dream.query request "state" in
  match code with
  | None -> Dream.respond "No code received"
  | Some code ->
    let open Lwt.Syntax in
    let token_request =
      Oidc.SimpleClient.make_token_request ~code ~discovery client
    in

    let* token_response = PiafOidc.request_descr_to_request token_request in
    let validated_token =
      Result.bind
        token_response
        (Oidc.SimpleClient.valid_token_of_string ~jwks ~discovery client)
    in

    let userinfo_request =
      Result.bind validated_token @@ fun token ->
      Oidc.SimpleClient.make_userinfo_request ~token ~discovery
    in

    let* userinfo =
      match userinfo_request with
      | Ok request_descr -> PiafOidc.request_descr_to_request request_descr
      | Error e -> Lwt_result.fail e
    in

    (match validated_token, userinfo with
    | Ok tokens, Ok userinfo ->
      let id_token = Option.value ~default:"no id_token" tokens.id_token in
      let access_token =
        Option.value ~default:"no access_token" tokens.access_token
      in
      let refresh_token =
        Option.value ~default:"no refresh_token" tokens.refresh_token
      in
      let session_update =
        Lwt.all
          [ Dream.put_session "id_token" id_token request
          ; Dream.put_session "access_token" access_token request
          ; Dream.put_session "refresh_token" refresh_token request
          ; Dream.put_session "userinfo" userinfo request
          ]
      in
      Lwt.bind session_update (fun _ ->
        Dream.log "Session updated";
        redirect_200 redirect_to)
    | Error e, _ ->
      let error_string = Oidc.Error.to_string e in
      Dream.error (fun m -> m "Token Error: %s" error_string);
      Dream.respond error_string
    | Ok _, Error e ->
      let error_string = Oidc.Error.to_string e in
      Dream.error (fun m -> m "Userinfo Error: %s" error_string);
      Dream.respond error_string)

let middleware
      ?(auth_endpoint = "/auth")
      ?(callback_endpoint = "/auth/callback")
      ?(redirect_to = "/")
      ?remember:_
      ?(scope = [ `OpenID; `Email; `Profile ])
      ~discovery
      ~jwks
      client
  =
  let auth_handler = auth_handler ~discovery ~client ~scope in
  let callback_handler =
    callback_handler ~redirect_to ~discovery ~jwks ~client
  in
  let routes =
    [ Dream.get auth_endpoint auth_handler
    ; Dream.get callback_endpoint callback_handler
    ]
  in

  let check_auth inner_handler request =
    let[@ocaml.warning "-3"] current_path =
      Dream.to_path @@ Dream.path request
    in
    if current_path <> auth_endpoint && current_path <> callback_endpoint
    then
      let id_token = Dream.session "id_token" request in
      let access_token = Dream.session "access_token" request in
      let refresh_token = Dream.session "refresh_token" request in
      let userinfo = Dream.session "userinfo" request in
      match id_token, access_token, refresh_token, userinfo with
      | Some _, Some _, Some _, Some _ -> inner_handler request
      | _ -> Dream.redirect ~code:302 request auth_endpoint
    else inner_handler request
  in

  Dream.pipeline [ check_auth; (fun _handler -> Dream.router routes) ]
