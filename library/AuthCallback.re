let make = (req: Morph.Request.t) => {
  open Lwt_result.Infix;

  let req_uri = req.request.target |> Uri.of_string;

  let oidc_client = Context.get_context(req);

  let state =
    Uri.get_query_param(req_uri, "state") |> CCOpt.get_or(~default="state");
  let code =
    Uri.get_query_param(req_uri, "code") |> CCOpt.get_or(~default="code");

  Morph.Session.get(req, ~key="state")
  |> Lwt_result.map_err(_ => `Msg("State not found in session"))
  >>= (
    session_state =>
      if (session_state == state) {
        Lwt_result.return();
      } else {
        Lwt_result.fail(`Msg("State missmatch"));
      }
  )
  >>= (
    () =>
      OidcClient.get_and_validate_id_token(~code, oidc_client)
      >>= (
        valid_token => {
          let id_token = Jose.Jwt.to_string(valid_token);
          Logs.info(m => m("JWT: %s", id_token));
          Morph.Session.set(req, ~value=id_token, ~key="id_token")
          |> Lwt_result.ok;
        }
      )
      |> Lwt.map(
           fun
           | Ok(_) => Morph.Response.redirect("/secure")
           | Error(_) => Morph.Response.unauthorized("no valid session"),
         )
  );
};
