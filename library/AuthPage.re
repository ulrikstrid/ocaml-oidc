let make = request => {
  open Lwt.Syntax;

  let oidc_client = Context.get_context(request);

  let state =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let nonce =
    Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

  let+ () = Morph.Session.set(request, ~key=state, ~value=state);

  let auth_uri = OidcClient.get_auth_uri(~nonce, ~state, oidc_client);

  Morph.Response.redirect(auth_uri);
};
