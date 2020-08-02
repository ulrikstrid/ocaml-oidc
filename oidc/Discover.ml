(* TODO: Add more fields *)
type t = {
  authorization_endpoint : string;
  token_endpoint : string;
  jwks_uri : string;
  userinfo_endpoint : string;
  issuer : string;
  registration_endpoint : string option;
}

(* TODO: Should maybe be a result? *)
let of_json json =
  Yojson.Safe.Util.
    {
      authorization_endpoint =
        json |> member "authorization_endpoint" |> to_string;
      token_endpoint = json |> member "token_endpoint" |> to_string;
      jwks_uri = json |> member "jwks_uri" |> to_string;
      userinfo_endpoint = json |> member "userinfo_endpoint" |> to_string;
      issuer = json |> member "issuer" |> to_string;
      registration_endpoint =
        json |> member "registration_endpoint" |> to_string_option;
    }

(* TODO: Should maybe be a result? *)
let of_string body = Yojson.Safe.from_string body |> of_json
