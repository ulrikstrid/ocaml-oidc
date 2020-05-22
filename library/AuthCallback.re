let find_jwk = (jwks: Jose.Jwks.t, kid: string) => {
  print_endline(CCList.length(jwks.keys) |> string_of_int);
  CCList.find_opt(
    (jwk: Jose.Jwk.t('a)) => {Jose.Jwk.get_kid(jwk) == kid},
    jwks.keys,
  );
};

let make = (req: Morph.Request.t) => {
  open Lwt.Syntax;

  let req_uri = req.request.target |> Uri.of_string;

  let oidc_client = Context.get_context(req);

  let code =
    Uri.get_query_param(req_uri, "code") |> CCOpt.get_or(~default="code");

  let* jwks_response_body = OidcClient.jwks(oidc_client);
  let* token_response_body = OidcClient.get_token(~code, oidc_client);

  switch (jwks_response_body, token_response_body) {
  | (Error(_), Error(_)) =>
    Morph.Response.unauthorized("Could not get neither jwks or token")
    |> Lwt.return
  | (Error(_), _) =>
    Morph.Response.unauthorized("Could not get jwks") |> Lwt.return
  | (_, Error(_)) =>
    Morph.Response.unauthorized("Could not get token") |> Lwt.return
  | (Ok(jwks), Ok(token_response_body)) =>
    Logs.info(m => m("token: %s", token_response_body));
    let valid_token =
      token_response_body
      |> Yojson.Basic.from_string
      |> Yojson.Basic.Util.member("id_token")
      |> Yojson.Basic.Util.to_string
      |> Jose.Jwt.of_string
      |> CCResult.flat_map((jwt: Jose.Jwt.t) => {
           let kid = jwt.header.kid;
           Logs.info(m => m("kid: %s", kid));
           find_jwk(jwks, kid)
           |> CCResult.of_opt
           |> CCResult.map_err(e => `Msg("JWK not found, " ++ e))
           |> CCResult.flat_map(jwk => {Jose.Jwt.validate(~jwk, jwt)});
         });

    let* _set_token =
      switch (valid_token) {
      | Ok(jwt) =>
        let id_token = Jose.Jwt.to_string(jwt);
        Logs.info(m => m("JWT: %s", id_token));
        Morph.Session.set(req, ~value=id_token, ~key="id_token");
      | Error(`Msg(e)) => Logs.err(m => m("%s", e)) |> Lwt.return
      | Error(`Expired) =>
        Logs.err(m => m("%s", "Token expired")) |> Lwt.return
      | Error(_) => Logs.err(m => m("Other error")) |> Lwt.return
      };

    let state =
      Uri.get_query_param(req_uri, "state") |> CCOpt.get_or(~default="state");

    // Validate that we have the session in store
    let+ session_state = Morph.Session.get(req, ~key=state);
    switch (session_state) {
    | Error(_) => Morph.Response.unauthorized("no valid session")
    | Ok(_) => Morph.Response.redirect("/secure")
    };
  };
};
