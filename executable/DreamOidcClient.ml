(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

let secret = Sys.getenv "OIDC_SECRET"
let client_id = Sys.getenv "OIDC_CLIENT_ID"

let provider_uri = Uri.of_string  "https://accounts.google.com"

let redirect_uri = Uri.of_string "http://localhost:8080/auth/callback"


let client =
  Oidc.Client.make
    ~secret
    ~response_types:["code"]
    ~grant_types:[]
    ~redirect_uris:[redirect_uri]
    ~token_endpoint_auth_method:"client_secret_post"
    client_id

let simple_client = OidcClientSimple.Static.make ~redirect_uri ~provider_uri client


let map_piaf_error e =
  `Msg (Piaf.Error.to_string e)

(*
Google has a bunch of different URLs so we will have to get back to this...

module HttpClient = struct
  let start () =
    let client = Piaf.Client.create provider_uri in
    Lwt_result.map_err map_piaf_error client

  let stop http_client =
    Piaf.Client.shutdown http_client

  let component = Archi_lwt.Component.make ~start ~stop
end
*)

module Discovery = struct
  open Lwt_result.Infix
  let start () =
    let uri = OidcClientSimple.Static.discovery_uri simple_client in
    Piaf.Client.Oneshot.get uri
    >>= (fun response -> Piaf.Body.to_string response.body)
    >|= (fun s -> 
      print_endline s;
      Oidc.Discover.of_string s)
    |> Lwt_result.map_err map_piaf_error

  let stop _ =
    Lwt.return ()

  let component = Archi_lwt.Component.make ~start ~stop
end

module WebServer = struct
  let dependencies : (unit, 'a, 'b) Archi_lwt.Component.deps = [ Discovery.component ]

  let (stop_promise, stopper) =
    Lwt.wait ()

  let start () discovery =
    Dream.serve ~stop:stop_promise
    @@ Dream.logger
    @@ Dream.cookie_sessions
    @@ Dream.router [
      Dream.get "/auth" (fun request ->
        let uri = OidcClientSimple.Static.get_auth_uri ~scope:["openid"; "email";] ~state:"state" ~discovery simple_client in
        Dream.redirect request @@ Uri.to_string uri
      );
      Dream.get "/auth/callback" (fun request ->
        let code = Dream.query "code" request in
        let _state = Dream.query "state" request in
        match code with
        | Some code ->
          let open Lwt_result.Infix in
          Dream.log "code: %s" code;
          let OidcClientSimple.Static.{ body; headers; uri; } = OidcClientSimple.Static.make_token_request ~code ~discovery simple_client in
          Dream.log "body: %s" (Option.get body);
          let body = Option.map Piaf.Body.of_string body in
          let response_body = (Piaf.Client.Oneshot.post ?body ~headers uri)
          >>= fun response -> Piaf.Body.to_string response.body in
          Lwt.bind response_body (function
          | Ok response -> Dream.respond response
          | Error e ->
            let error_string = Piaf.Error.to_string e in
            Dream.error (fun m -> m "Error: %s" error_string);
            Dream.respond error_string)
        | None ->
          Dream.respond "No code received"
      )
    ]
    @@ Dream.not_found
    |> Lwt.map Result.ok

  let stop () =
    Lwt.wakeup stopper () |> Lwt.return

  let component = Archi_lwt.Component.using ~start ~stop ~dependencies
end

let system =
  Archi_lwt.System.make [
    "Discovery document", Discovery.component;
    "HTTP server", WebServer.component;
  ]

let main () =
  let () = Mirage_crypto_rng_unix.initialize() in
  let open Lwt.Infix in

  Archi_lwt.System.start () system
  >|= (function
  | Ok system ->
    Sys.(
      set_signal sigint (Signal_handle (fun _ -> Archi_lwt.System.stop system |> ignore))
    )
  | Error `Msg error ->
    prerr_endline error;
    exit 1
  | Error `Cycle_found ->
    prerr_endline "Dependency cycle found";
    exit 1
  )

let () = Lwt_main.run @@ main ()