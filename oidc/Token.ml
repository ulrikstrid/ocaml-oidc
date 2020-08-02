open Utils

type token_type = Bearer

type t = {
  token_type : token_type;
  scope : string option;
  expires_in : int option;
  ext_exipires_in : int option;
  access_token : string option;
  refresh_token : string option;
  id_token : string;
}

let of_json json =
  let module Json = Yojson.Safe.Util in
  {
    token_type = Bearer;
    (* Only Bearer is supported by OIDC, TODO = return a error if it is not Bearer *)
    scope = json |> Json.member "scope" |> Json.to_string_option;
    expires_in = json |> Json.member "expires_in" |> Json.to_int_option;
    ext_exipires_in =
      json |> Json.member "ext_exipires_in" |> Json.to_int_option;
    access_token = json |> Json.member "access_token" |> Json.to_string_option;
    refresh_token = json |> Json.member "refresh_token" |> Json.to_string_option;
    id_token = json |> Json.member "id_token" |> Json.to_string;
  }

let of_string str = Yojson.Safe.from_string str |> of_json

let clean_string str =
  str
  |> Uunf_string.normalize_utf_8 `NFD
  |> Uri.pct_encode
  |> RString.replace ~sub:"+" ~by:"%2B"
  |> RString.replace ~sub:":" ~by:"%3A"

let basic_auth ~client_id ~secret =
  (* https://tools.ietf.org/html/rfc6749#appendix-B *)
  let username = clean_string client_id in
  let password = clean_string secret in

  let b64 =
    RBase64.encode_string_url (Printf.sprintf "%s:%s" username password)
  in
  ("Authorization", "Basic " ^ b64)
