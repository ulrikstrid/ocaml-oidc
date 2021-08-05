let redirect_uri = Uri.of_string "http://localhost:8080/auth/callback"

let client =
  Oidc.Client.make
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
             Oidc.Parameters.make ~scope:["repo"] client ~redirect_uri in
           let uri = Uri.of_string "https://github.com/login/oauth/authorize" in
           let redirect_uri =
             Uri.with_query uri (Oidc.Parameters.to_query params) in
           Dream.redirect request (Uri.to_string redirect_uri) );
         ( Dream.get "/auth/callback" @@ fun request ->
           match Dream.query "code" request with
           | None -> Dream.html ~status:`Unauthorized "error"
           | Some code ->
             let uri =
               Uri.of_string "https://github.com/login/oauth/access_token" in
             let request_body =
               Oidc.Token.Request.make ~client ~grant_type:"code"
                 ~scope:["repo"] ~redirect_uri ~code
               |> Oidc.Token.Request.to_body_string in
             let open Lwt.Syntax in
             let headers = Cohttp.Header.init_with "accpet" "application/json" in
             let* token_response =
               Cohttp_lwt_unix.Client.post ~body:(`String request_body) ~headers
                 uri
             in
             let* body = Cohttp_lwt.Body.to_string (snd token_response) in
             let () = Dream.info (fun m -> m "body: %s" body) in
             let token_response = Oidc.Token.Response.of_string body in
             let () =
               Dream.info (fun m -> m "id_token: %s" token_response.id_token)
             in
             let+ response =
               Dream.html
                 ("auth callback " ^ Option.get token_response.access_token)
             in
             response );
       ]
  @@ Dream.not_found
