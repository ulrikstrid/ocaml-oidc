type session = {
  auth_json: Yojson.Basic.t,
  sitekey: string,
  nonce: string,
};

module Env = {
  let key = Hmap.Key.create();
};

let get_context = (request: Morph.Request.t) =>
  Hmap.get(Env.key, request.ctx);

let middleware: (~context: OidcClient.t) => Morph.Server.middleware =
  (~context: OidcClient.t, handler, request) => {
    let next_request = {
      ...request,
      ctx: Hmap.add(Env.key, context, request.ctx),
    };
    handler(next_request);
  };
