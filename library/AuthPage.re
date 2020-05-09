let make = request => {
  open Context;

  let context = Context.get_context(request);

  let cookie_key =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let nonce =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let paremeters =
    Oidc.Parameters.{
      response_type: ["code"],
      client: context.client,
      redirect_uri: context.client.redirect_uri,
      scope: ["openid"],
      state: Some(cookie_key),
      nonce,
      claims: None,
      max_age: None,
      display: None,
      prompt: None,
    };

  let query = Oidc.Parameters.to_query(paremeters);

  Morph.Response.redirect(context.discovery.authorization_endpoint ++ query) |> Lwt.return;
};
