let make = (req: Morph.Request.t) => {
  open Lwt_result.Infix;

  let req_uri = req.request.target |> Uri.of_string;

  let oidc_client = Context.get_context(req);

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
