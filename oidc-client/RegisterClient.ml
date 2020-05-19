let req ~registration_uri : (string, Piaf.Error.t) Lwt_result.t =
  let open Lwt_result.Syntax in
  let meta =
    Oidc.ClientMeta.make
      ~redirect_uris:[ "http://localhost:4040/auth/cb" ]
      ~contacts:[ "ulrik.strid@outlook.com" ]
      ~response_types:[ "code" ] ~grant_types:[ "authorization_code" ]
      ~token_endpoint_auth_method:"client_secret_post" ()
  in
  let meta_string = Oidc.ClientMeta.to_string meta in

  let* res =
    Piaf.Client.Oneshot.request ~meth:`POST
      ~body:(Piaf.Body.of_string meta_string)
      registration_uri
  in
  Piaf.Body.to_string res.body

let req ~registration_uri :
    (Oidc.DynamicRegistration.response, string) Lwt_result.t =
  req ~registration_uri
  |> Lwt.map (function
       | Ok body_string ->
           Oidc.DynamicRegistration.response_of_string body_string
       | Error e -> Error (Piaf.Error.to_string e))
