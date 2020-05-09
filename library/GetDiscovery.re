let req = (~provider_uri, ()) => {
  open Lwt_result.Infix;
  let uri =
    "https://"
    ++ Uri.to_string(provider_uri)
    ++ "/.well-known/openid-configuration"
    |> Uri.of_string;

  Piaf.Client.Oneshot.request(~meth=`GET, uri)
  >>= (res => Piaf.Response.body(res) |> Piaf.Body.to_string |> Lwt_result.ok);
};
