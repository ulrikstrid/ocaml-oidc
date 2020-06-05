let make: string => Morph.Server.handler =
  (provider: string, request) => {
    open Lwt.Syntax;

    Logs.info(m => m("Starting login with %s", provider));

    let oidc_client = Context.get_client(request, provider);

    let state =
      Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

    let nonce =
      Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

    Logs.warn(m => m("nonce: %s", nonce));

    let* () =
      Morph.Session.set(request, ~expiry=3600L, ~key="state", ~value=state);
    let* () =
      Morph.Session.set(request, ~expiry=3600L, ~key="nonce", ~value=nonce);
    let* () = Morph.Session.set(request, ~key="provider", ~value=provider);

    let+ auth_uri = OidcClient.get_auth_uri(~nonce, ~state, oidc_client);

    switch (auth_uri) {
    | Ok(auth_uri) =>
      Logs.info(m => m("auth_uri %s", auth_uri));
      Morph.Response.redirect(auth_uri);
    | Error(e) => Error(`Server(Piaf.Error.to_string(e)))
    };
  };
