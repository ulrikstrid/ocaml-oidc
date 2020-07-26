module RBase64 = struct
  let encode_string_url str =
    Base64.encode_string ~alphabet:Base64.uri_safe_alphabet str
end

module RHeader = struct
  let basic_auth username password =
    let () =
      Logs.info (fun m -> m "username: %s\npassword: %s" username password)
    in
    (* https://tools.ietf.org/html/rfc6749#appendix-B *)
    let password = Uunf_string.normalize_utf_8 `NFD password in
    let username = Uunf_string.normalize_utf_8 `NFD username in
    let username = Uri.pct_encode username in
    let password = Uri.pct_encode password in
    let username = CCString.replace ~sub:"+" ~by:"%2B" username in
    let password = CCString.replace ~sub:"+" ~by:"%2B" password in
    let username = CCString.replace ~sub:":" ~by:"%3A" username in
    let password = CCString.replace ~sub:":" ~by:"%3A" password in
    let () =
      Logs.info (fun m ->
          m "fixed_username: %s\nfixed_password: %s" username password)
    in
    let str = Printf.sprintf "%s:%s" username password in
    let b64 = RBase64.encode_string_url str in
    ("Authorization", "Basic " ^ b64)
end
