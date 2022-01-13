let clean_string = Uri.pct_encode ~component:`Userinfo

let basic_auth ~client_id ~secret =
  (* https://tools.ietf.org/html/rfc6749#appendix-B *)
  let username = clean_string client_id in
  let password = clean_string secret in

  let b64 =
    Utils.RBase64.encode_string (Printf.sprintf "%s:%s" username password)
  in
  ("Authorization", "Basic " ^ b64)

module Request = TokenRequest
module Response = TokenResponse
