type display =
  | Page
  | Popup
  | Touch
  | Wap;

let string_to_display_opt =
  fun
  | "page" => Some(Page)
  | "popup" => Some(Popup)
  | "touch" => Some(Touch)
  | "wap" => Some(Wap)
  | _ => None;

type prompt =
  | None
  | Login
  | Consent
  | Select_account;

let string_to_prompt_opt =
  fun
  | "none" => Some(None)
  | "login" => Some(Login)
  | "consent" => Some(Consent)
  | "select_account" => Some(Select_account)
  | _ => None;

type t = {
  response_type: list(string),
  client: Client.t,
  redirect_uri: string,
  scope: list(string), // Must include at least the openid scope
  state: option(string),
  nonce: string,
  claims: option(Yojson.Basic.t),
  max_age: option(int),
  display: option(display),
  prompt: option(prompt),
};

let to_query = t => {
  "?"
  ++ (
    [
      Some(("response_type", t.response_type)),
      Some(("client_id", [t.client.id])),
      Some(("redirect_uri", [t.redirect_uri])),
      Some(("scope", [CCString.concat(" ", t.scope)])),
      CCOpt.map(state => ("state", [state]), t.state),
      Some(("nonce", [t.nonce])),
      CCOpt.map(
        claims => {("claims", [claims |> Yojson.Basic.to_string])},
        t.claims,
      ),
    ]
    |> CCList.filter_map(a => a)
    |> Uri.encoded_of_query
  );
};

type parse_state =
  | Invalid(string)
  | UnauthorizedClient(Client.t)
  | InvalidScope(Client.t)
  | InvalidWithClient(Client.t)
  | InvalidWithRedirectUri(string)
  | Valid(t);

let get_client = (~clients, ~client_id, ()) => {
  switch (client_id) {
  | Some(client_id) =>
    CCList.find_opt((client: Client.t) => client.id == client_id, clients)
    |> (
      fun
      | Some(client) => Ok(client)
      | None => Error("No client found")
    )
  | None => Error("No client_id provided")
  };
};

let parse_query = (~clients, uri) => {
  let getQueryParam = Uri.get_query_param(uri);

  let claims =
    getQueryParam("claims") |> CCOpt.map(Yojson.Basic.from_string);

  let response_type =
    getQueryParam("response_type")
    |> CCOpt.map(String.split_on_char(' '))
    |> CCOpt.map(response_type => Ok(response_type))
    |> CCOpt.get_or(~default=Error("No response_type"))
    |> CCResult.catch(
         ~ok=
           response_type =>
             if (CCList.exists(rt => rt == "code", response_type)) {
               Ok(response_type);
             } else {
               Error("response_type doesn't include code");
             },
         ~err=err => Error(err),
       );

  let redirect_uri =
    getQueryParam("redirect_uri")
    |> CCOpt.map(redirect_uri => Ok(redirect_uri))
    |> CCOpt.get_or(~default=Error("No redirect_uri"));

  let client =
    get_client(~clients, ~client_id=getQueryParam("client_id"), ());

  let scope =
    getQueryParam("scope") |> CCOpt.map(String.split_on_char(' '));

  let max_age = getQueryParam("max_age") |> CCOpt.flat_map(CCInt.of_string);

  switch (client, response_type, redirect_uri, scope) {
  | (Ok(client), Ok(response_type), Ok(redirect_uri), Some(scope))
      when client.redirect_uri == redirect_uri =>
    Valid({
      response_type,
      client,
      redirect_uri,
      scope,
      state: getQueryParam("state"),
      nonce: getQueryParam("nonce") |> CCOpt.get_or(~default="12345"),
      claims,
      max_age,
      display:
        getQueryParam("display") |> CCOpt.flat_map(string_to_display_opt),
      prompt:
        getQueryParam("prompt") |> CCOpt.flat_map(string_to_prompt_opt),
    })
  | (Ok(client), Ok(_), _, Some(_)) => UnauthorizedClient(client)
  | (Ok(client), Error(_e), _, _) => InvalidWithClient(client)
  | (Ok(client), _, _, None) => InvalidScope(client)
  | (_, _, Ok(redirect_uri), _) => InvalidWithRedirectUri(redirect_uri)
  | (Error(client_id_msg), Ok(_), Error(redirect_uri_msg), _) =>
    Invalid(String.concat(", ", [client_id_msg, redirect_uri_msg]))
  | (
      Error(client_id_msg),
      Error(response_type_msg),
      Error(redirect_uri_msg),
      _,
    ) =>
    Invalid(
      String.concat(
        ", ",
        [client_id_msg, response_type_msg, redirect_uri_msg],
      ),
    )
  };
};
