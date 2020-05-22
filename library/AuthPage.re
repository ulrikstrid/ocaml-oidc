let make = request => {
  open Lwt.Syntax;

  let oidc_client = Context.get_context(request);

  let state =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let nonce =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let paremeters =
    OidcClient.get_auth_parameters(~nonce, ~state, oidc_client);

  let query = Oidc.Parameters.to_query(paremeters);

  let+ () = Morph.Session.set(request, ~key=state, ~value=state);

  Morph.Response.redirect(
    oidc_client.discovery.authorization_endpoint ++ query,
  );
};
