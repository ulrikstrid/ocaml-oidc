let make = (req: Morph.Request.t) => {
  open Lwt_result.Infix;
  open Lwt_result.Syntax;

  let req_uri = req.request.target |> Uri.of_string;

  let* provider =
    Morph.Session.get(req, ~key="provider")
    |> Lwt_result.map_err(_ => `Msg("No provider set in session"));
  let oidc_client = Context.get_client(req, provider);

  Morph.Session.get(req, ~key="state")
  |> Lwt_result.map_err(_ => `Msg("State not found in session"))
  >>= (
    state => OidcClient.get_auth_result(~uri=req_uri, ~state, oidc_client)
  )
  >>= (
    token =>
      Lwt_result.ok @@
      Morph.Session.set(
        req,
        ~value=Jose.Jwt.to_string(token),
        ~key="id_token",
      )
  )
  |> Lwt.map(
       fun
       | Ok(_) => Morph.Response.redirect("/secure")
       | Error(_) => Morph.Response.unauthorized("no valid session"),
     );
};
