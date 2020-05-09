type session = {
  auth_json: Yojson.Basic.t,
  sitekey: string,
  nonce: string,
};

let session_hash: Hashtbl.t(string, session) = Hashtbl.create(64);

let set_session: (string, session) => unit =
  (key, value) => Hashtbl.add(session_hash, key, value);

let get_session: string => option(session) =
  key => Hashtbl.find_opt(session_hash, key);

let delete_session: string => unit = key => Hashtbl.remove(session_hash, key);

type t = {
  discovery: Oidc.Discover.t,
  client: Oidc.Client.t,
  set_session: (string, session) => unit,
  get_session: string => option(session),
  delete_session: string => unit,
};

let make = (~discovery, ~client_id, ~redirect_uri, ~secret, ()) => {
  {
    client: {
      id: client_id,
      redirect_uri,
      secret,
    },
    discovery,
    set_session,
    get_session,
    delete_session,
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
