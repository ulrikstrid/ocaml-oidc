open Utils

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
