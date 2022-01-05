let redirect_uri = Uri.of_string "http://localhost:8080/auth/callback"

let client =
  Oauth.Client.make
    ~secret:(Sys.getenv "oauth_secret")
    ~response_types:["code"] ~grant_types:[] ~redirect_uris:[redirect_uri]
    ~token_endpoint_auth_method:"code"
    (Sys.getenv "oauth_client_id")

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.cookie_sessions
  @@ Dream.router
       [
         ( Dream.get "/auth" @@ fun request ->
           let params =
             Oauth.Parameters.make ~scope:["repo"; "read:user"] client
               ~redirect_uri in
           let uri = Uri.of_string "https://github.com/login/oauth/authorize" in
           let redirect_uri =
             Uri.with_query uri (Oauth.Parameters.to_query params) in
           Dream.redirect request (Uri.to_string redirect_uri) );
         ( Dream.get "/auth/callback" @@ fun request ->
           match Dream.query "code" request with
           | None -> Dream.html ~status:`Unauthorized "error"
           | Some code ->
             let uri =
               Uri.of_string "https://github.com/login/oauth/access_token" in
             let request_body =
               Oauth.Token.Request.make ~client ~grant_type:"code"
                 ~scope:["repo"] ~redirect_uri ~code
               |> Oauth.Token.Request.to_body_string in
             let open Lwt.Syntax in
             let headers = Cohttp.Header.init_with "Accept" "application/json" in
             let* token_response =
               Cohttp_lwt_unix.Client.post ~body:(`String request_body) ~headers
                 uri
             in
             let* body = Cohttp_lwt.Body.to_string (snd token_response) in
             let () = Dream.info (fun m -> m "body: %s" body) in
             let token_response = Oauth.Token.Response.of_string body in
             let* user =
               Cohttp_lwt_unix.Client.get
                 ~headers:
                   (Cohttp.Header.init_with "Authorization"
                      ("Bearer " ^ token_response.access_token))
                 (Uri.of_string "https://api.github.com/user")
             in
             let* user = Cohttp_lwt.Body.to_string (snd user) in
             let+ response = Dream.html ("auth callback " ^ user) in
             response );
       ]
  @@ Dream.not_found
