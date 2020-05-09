let req = (~discovery: Oidc.Discover.t, ()) => {
  open Lwt_result.Infix;
  let uri = Uri.of_string(discovery.jwks_uri);

  Piaf.Client.Oneshot.request(~meth=`GET, uri)
  >>= (res => Piaf.Response.body(res) |> Piaf.Body.to_string |> Lwt_result.ok);
};
