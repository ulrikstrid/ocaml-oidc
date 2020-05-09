type t = {
  authorization_endpoint: string,
  token_endpoint: string,
  jwks_uri: string,
  userinfo_endpoint: string,
};

let of_json = json =>
  Yojson.Basic.Util.{
    authorization_endpoint:
      json |> member("authorization_endpoint") |> to_string,
    token_endpoint: json |> member("token_endpoint") |> to_string,
    jwks_uri: json |> member("jwks_uri") |> to_string,
    userinfo_endpoint: json |> member("userinfo_endpoint") |> to_string,
  };

let of_string = body => Yojson.Basic.from_string(body) |> of_json;
