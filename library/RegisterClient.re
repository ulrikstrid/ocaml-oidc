let req = () => {
  open Lwt_result.Infix;

  let meta =
    Oidc.ClientMeta.make(
      ~redirect_uris=["http://localhost:8080/auth/cb"],
      ~contacts=["ulrik.strid@outlook.com"],
      ~response_types=["code"],
      ~grant_types=["authorization_code"],
      ~token_endpoint_auth_method="client_secret_post",
      (),
    )
    |> Oidc.ClientMeta.to_string;

  Piaf.Client.Oneshot.request(
    ~meth=`POST,
    ~body=Piaf.Body.of_string(meta),
    Uri.of_string(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-response_type-code/registration",
    ),
  )
  >>= (res => Piaf.Response.body(res) |> Piaf.Body.to_string |> Lwt_result.ok);
};
