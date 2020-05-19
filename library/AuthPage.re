let make = request => {
  open Lwt.Syntax;
  open Context;

  let context = Context.get_context(request);

  let state =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let nonce =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let paremeters =
    Oidc.Parameters.{
      response_type: ["code"],
      client: context.client,
      redirect_uri: context.client.redirect_uri,
      scope: ["openid"],
      state: Some(state),
      nonce,
      claims: None,
      max_age: None,
      display: None,
      prompt: None,
    };

  let query = Oidc.Parameters.to_query(paremeters);

  let+ () = Morph.Session.set(request, ~key=state, ~value=state);

  Morph.Response.redirect(
    context.oidc_client.discovery.authorization_endpoint ++ query,
  );
};
