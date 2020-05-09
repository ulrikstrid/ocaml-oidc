let find_jwk = (jwks: Jose.Jwks.t, kid: string) => {
  print_endline(CCList.length(jwks.keys) |> string_of_int);
  CCList.find_opt(
    (jwk: Jose.Jwk.t('a)) => {Jose.Jwk.get_kid(jwk) == kid},
    jwks.keys,
  );
};

let make = (req: Morph.Request.t) => {
  open Context;

  let req_uri = req.request.message.target |> Uri.of_string;

  let context = Context.get_context(req);

  let code =
    Uri.get_query_param(req_uri, "code") |> CCOpt.get_or(~default="code");

  let%lwt jwks_response_body = GetJwks.req(~discovery=context.discovery, ());
  let%lwt token_response_body =
    GetToken.req(~discovery=context.discovery, ~client=context.client, code);

  CCResult.both(jwks_response_body, token_response_body)
  |> CCResult.map(((jwks_response_body, token_response_body)) => {
       Logs.info(m => m("%s", jwks_response_body));

       let jwks = Jose.Jwks.of_string(jwks_response_body);
       Logs.info(m => m("%s", token_response_body));
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

       switch (valid_token) {
       | Ok(jwt) => Logs.info(m => m("JWT: %s", Jose.Jwt.to_string(jwt)))
       | Error(`Msg(e)) => Logs.err(m => m("%s", e))
       | Error(`Expired) => Logs.err(m => m("%s", "Token expired"))
       | Error(_) => Logs.err(m => m("Other error"))
       };

       let state =
         Uri.get_query_param(req_uri, "state")
         |> CCOpt.get_or(~default="state");

       // Validate that we have the session in store
       switch (context.get_session(state)) {
       | None => Morph.Response.unauthorized("no valid session") |> Lwt.return
       | Some(_) =>
         Morph.Response.redirect(
           Sys.getenv("OIDC_REDIRECT_URI") ++ "/guest/redirect/" ++ state,
         )
         |> Lwt.return
       };
     })
  |> (
    fun
    | Ok(_) => Morph.Response.ok()
    | Error(e) => Morph.Response.unauthorized(e)
  )
  |> Lwt.return;
};
