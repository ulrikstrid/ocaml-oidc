let req = (~discovery: Oidc.Discover.t, ~client: Oidc.Client.t, code) => {
  open Lwt_result.Infix;
  let uri = Uri.of_string(discovery.token_endpoint);

  let body =
    Printf.sprintf(
      "grant_type=authorization_code&scope=openid&code=%s&client_id=%s&client_secret=%s&redirect_uri=%s",
      code,
      client.id,
      client.secret |> CCOpt.get_or(~default="secret"),
      client.redirect_uri,
    )
    |> Piaf.Body.of_string;

  Piaf.Client.Oneshot.request(
    ~meth=`POST,
    ~headers=[
      ("Content-Type", "application/x-www-form-urlencoded"),
      ("Accept", "application/json"),
    ],
    ~body,
    uri,
  )
  >>= (res => Piaf.Response.body(res) |> Piaf.Body.to_string |> Lwt_result.ok);
};
