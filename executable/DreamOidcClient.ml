(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

let secret = Sys.getenv "OIDC_SECRET"
let client_id = Sys.getenv "OIDC_CLIENT_ID"
let provider_uri = Uri.of_string "https://accounts.google.com"
let redirect_uri = Uri.of_string "http://localhost:8080/auth/callback"

let simple_client =
  Oidc.SimpleClient.make ~redirect_uri ~provider_uri ~secret client_id

(*
Google has a bunch of different URLs so we will have to get back to this...

module HttpClient = struct
  let start () =
    let client = Piaf.Client.create provider_uri in
    Lwt_result.map_error map_piaf_error client

  let stop http_client =
    Piaf.Client.shutdown http_client

  let component = Archi_lwt.Component.make ~start ~stop
end
*)

module Discovery = struct
  open Lwt_result.Infix

  let start () =
    let uri = Oidc.SimpleClient.discovery_uri simple_client in
    Piaf.Client.Oneshot.get uri
    >>= (fun response -> Piaf.Body.to_string response.body)
    >|= (fun s -> Oidc.Discover.of_string s)
    |> Lwt_result.map_error PiafOidc.map_piaf_error

  let stop _ = Lwt.return ()
  let component = Archi_lwt.Component.make ~start ~stop
end

module JWKs = struct
  open Lwt_result.Infix

  let dependencies : (unit, 'a, 'b) Archi_lwt.Component.deps =
    [ Discovery.component ]

  let start () (discovery : Oidc.Discover.t) =
    Piaf.Client.Oneshot.get discovery.jwks_uri
    >>= PiafOidc.to_string_body
    >|= Jose.Jwks.of_string
    |> Lwt_result.map_error PiafOidc.map_piaf_error

  let stop _ = Lwt.return ()
  let component = Archi_lwt.Component.using ~start ~stop ~dependencies
end

module WebServer = struct
  let dependencies : (unit, 'a, 'b) Archi_lwt.Component.deps =
    [ Discovery.component; JWKs.component ]

  let stop_promise, stopper = Lwt.wait ()

  let start () discovery jwks =
    Dream.serve ~stop:stop_promise
    @@ Dream.logger
    @@ Dream.cookie_sessions
    @@ Dream.router [ (Dream.get "/" @@ fun _ -> Dream.html "Unsecured route") ]
    @@ DreamOidcMiddleware.middleware
         ~redirect_to:"/secure"
         ~discovery
         ~jwks
         simple_client
    @@ Dream.router
         [ ( Dream.get "/secure" @@ fun request ->
             let id_token = Dream.session "id_token" request |> Option.get in
             let access_token =
               Dream.session "access_token" request |> Option.get
             in
             let refresh_token =
               Dream.session "refresh_token" request |> Option.get
             in
             let userinfo = Dream.session "userinfo" request |> Option.get in
             Dream.html
             @@ Printf.sprintf
                  "<html><body><p>id_token</p><pre>%s</pre><p>userinfo</p><pre>%s</pre><p>access_token</p><pre>%s</pre><p>refresh_token</p><pre>%s</pre></body></html>"
                  id_token
                  userinfo
                  access_token
                  refresh_token )
         ]
    @@ Dream.not_found
    |> Lwt.map Result.ok

  let stop () = Lwt.wakeup stopper () |> Lwt.return
  let component = Archi_lwt.Component.using ~start ~stop ~dependencies
end

let system =
  Archi_lwt.System.make
    [ "Discovery document", Discovery.component
    ; "HTTP server", WebServer.component
    ]

let main () =
  let () = Dream.initialize_log ~enable:true () in
  let open Lwt.Infix in
  Archi_lwt.System.start () system >|= function
  | Ok system ->
    Sys.(
      set_signal
        sigint
        (Signal_handle (fun _ -> Archi_lwt.System.stop system |> ignore)))
  | Error (`Msg error) ->
    prerr_endline error;
    exit 1
  | Error `Cycle_found ->
    prerr_endline "Dependency cycle found";
    exit 1

let () = Lwt_main.run @@ main ()
