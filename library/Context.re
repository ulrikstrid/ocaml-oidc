type session = {
  auth_json: Yojson.Basic.t,
  sitekey: string,
  nonce: string,
};

type t = {
  oidc_client: OidcClient.t,
  client: Oidc.Client.t,
};

let make = (~oidc_client: OidcClient.t, ~client_id, ~secret, ()) => {
  {
    client: {
      id: client_id,
      redirect_uri: Uri.to_string(oidc_client.redirect_uri),
      secret,
    },
    oidc_client,
  };
};

module Env = {
  let key = Hmap.Key.create();
};

let get_context = (request: Morph.Request.t) =>
  Hmap.get(Env.key, request.ctx);

let middleware: (~context: t) => Morph.Server.middleware =
  (~context: t, handler, request) => {
    let next_request = {
      ...request,
      ctx: Hmap.add(Env.key, context, request.ctx),
    };
    handler(next_request);
  };
