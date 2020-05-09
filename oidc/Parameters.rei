type display =
  | Page
  | Popup
  | Touch
  | Wap;

type prompt =
  | None
  | Login
  | Consent
  | Select_account;

type t = {
  response_type: list(string),
  client: Client.t,
  redirect_uri: string,
  scope: list(string),
  state: option(string),
  nonce: string,
  claims: option(Yojson.Basic.t),
  max_age: option(int),
  display: option(display),
  prompt: option(prompt),
};

type parse_state =
  | Invalid(string)
  | UnauthorizedClient(Client.t)
  | InvalidScope(Client.t)
  | InvalidWithClient(Client.t)
  | InvalidWithRedirectUri(string)
  | Valid(t);

let to_query: t => string;
let parse_query: (~clients: list(Client.t), Uri.t) => parse_state;
