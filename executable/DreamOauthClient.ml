let redirect_uri = Uri.of_string "http://localhost:8080/auth/callback"

let client =
  Oidc.Client.make ~secret:(Sys.getenv "OIDC_SECRET") ~response_types:["code"]
    ~grant_types:[] ~redirect_uris:[redirect_uri]
    ~token_endpoint_auth_method:"code"
    (Sys.getenv "OIDC_CLIENT_ID")

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.cookie_sessions
  @@ Dream.router
       [
         ( Dream.get "/auth" @@ fun request ->
           let params =
             Oidc.Parameters.make
               ~scope:[`S "repo"; `S "read:user"]
               client ~redirect_uri
           in
           let uri = Uri.of_string "https://github.com/login/oauth/authorize" in
           let redirect_uri =
             Uri.with_query uri (Oidc.Parameters.to_query params)
           in
           Dream.redirect request (Uri.to_string redirect_uri) );
         ( Dream.get "/auth/callback" @@ fun request ->
           match Dream.query "code" request with
           | None -> Dream.html ~status:`Unauthorized "error"
           | Some code ->
             let uri =
               Uri.of_string "https://github.com/login/oauth/access_token"
             in
             let request_body =
               Oidc.Token.Request.make ~client ~grant_type:"code"
                 ~scope:[`S "repo"]
                 ~redirect_uri ~code
               |> Oidc.Token.Request.to_body_string
             in
             let open Lwt.Syntax in
             let headers =
               Cohttp.Header.init_with "Accept" "application/json"
             in
             let* token_response =
               Cohttp_lwt_unix.Client.post ~body:(`String request_body) ~headers
                 uri
             in
             let* body = Cohttp_lwt.Body.to_string (snd token_response) in
             let () = Dream.info (fun m -> m "body: %s" body) in
             let token_response = Oidc.Token.Response.of_string body in
             let access_token = Option.get token_response.access_token in
             let* user =
               Cohttp_lwt_unix.Client.get
                 ~headers:
                   (Cohttp.Header.init_with "Authorization"
                      ("Bearer " ^ access_token))
                 (Uri.of_string "https://api.github.com/user")
             in
             let* user = Cohttp_lwt.Body.to_string (snd user) in
             let+ response = Dream.html ("auth callback " ^ user) in
             response );
       ]
  @@ Dream.not_found
