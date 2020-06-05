type t = {
  name : string;
  category : string;
  description : string;
  info : string;
}

let datas =
  [
    {
      name = "rp-response_type-code";
      category = "Response Type and Response Mode";
      description =
        "Make an authentication request using the Authorization Code Flow.";
      info = "An authentication response containing an authorization code.";
    };
    {
      name = "rp-scope-userinfo-claims";
      category = "scope Request Parameter";
      description = "Request claims using scope values.";
      info =
        "A UserInfo Response containing the requested claims. If no access \
         token is issued (when using Implicit Flow with \
         response_type='id_token') the ID Token contains the requested claims.";
    };
    {
      name = "rp-nonce-invalid";
      category = "nonce Request Parameter";
      description =
        "Pass a 'nonce' value in the Authentication Request. Verify the \
         'nonce' value returned in the ID Token.";
      info =
        "Identify that the 'nonce' value in the ID Token is invalid and reject \
         the ID Token.";
    };
    {
      name = "rp-token_endpoint-client_secret_basic";
      category = "Client Authentication";
      description =
        "Use the 'client_secret_basic' method to authenticate at the \
         Authorization Server when using the token endpoint.";
      info = "A Token Response, containing an ID token.";
    };
    {
      name = "rp-id_token-kid-absent-single-jwks";
      category = "ID Token";
      description =
        "Request an ID token and verify its signature using a single matching \
         key provided by the Issuer.";
      info =
        "Use the single matching key out of the Issuer's published set to \
         verify the ID Tokens signature and accept the ID Token after doing ID \
         Token validation.";
    };
    {
      name = "rp-id_token-iat";
      category = "ID Token";
      description = "\tRequest an ID token and verify its 'iat' value.";
      info =
        "Identify the missing 'iat' value and reject the ID Token after doing \
         ID Token validation.";
    };
    {
      name = "rp-id_token-aud";
      category = "ID Token";
      description =
        "Request an ID token and compare its aud value to the Relying Party's \
         'client_id'.";
      info =
        "Identify that the 'aud' value is missing or doesn't match the \
         'client_id' and reject the ID Token after doing ID Token validation.";
    };
    {
      name = "rp-id_token-kid-absent-multiple-jwks";
      category = "ID Token";
      description =
        "Request an ID token and verify its signature using the keys provided \
         by the Issuer.";
      info =
        "Identify that the 'kid' value is missing from the JOSE header and \
         that the Issuer publishes multiple keys in its JWK Set document \
         (referenced by 'jwks_uri'). The RP can do one of two things; reject \
         the ID Token since it can not by using the kid determined which key \
         to use to verify the signature. Or it can just test all possible keys \
         and hit upon one that works, which it will in this case.";
    };
    {
      name = "rp-id_token-sig-none";
      category = "ID Token";
      description =
        "Use Code Flow and retrieve an unsigned ID Token. This test is only \
         applicable when response_type='code'";
      info = "Accept the ID Token after doing ID Token validation.";
    };
    {
      name = "rp-id_token-sig-rs256";
      category = "ID Token";
      description =
        "Request an signed ID Token. Verify the signature on the ID Token \
         using the keys published by the Issuer.";
      info = "Accept the ID Token after doing ID Token validation.";
    };
    {
      name = "rp-id_token-sub";
      category = "ID Token";
      description = "Request an ID token and verify it contains a sub value.";
      info = "Identify the missing 'sub' value and reject the ID Token.";
    };
    {
      name = "rp-id_token-bad-sig-rs256";
      category = "ID Token";
      description =
        "Request an ID token and verify its signature using the keys provided \
         by the Issuer.";
      info =
        "Identify the invalid signature and reject the ID Token after doing ID \
         Token validation.";
    };
    {
      name = "rp-id_token-issuer-mismatch";
      category = "ID Token";
      description = "\tRequest an ID token and verify its 'iss' value.";
      info =
        "Identify the incorrect 'iss' value and reject the ID Token after \
         doing ID Token validation.";
    };
    {
      name = "rp-userinfo-bad-sub-claim";
      category = "UserInfo Endpoint";
      description =
        "\tMake a UserInfo Request and verify the 'sub' value of the UserInfo \
         Response by comparing it with the ID Token's 'sub' value.";
      info =
        "Identify the invalid 'sub' value and reject the UserInfo Response.";
    };
    {
      name = "rp-userinfo-bearer-header";
      category = "UserInfo Endpoint";
      description =
        "Pass the access token using the \"Bearer\" authentication scheme \
         while doing the UserInfo Request.";
      info = "A UserInfo Response.";
    };
  ]

let redirect_uri = Sys.getenv "OIDC_REDIRECT_URI"

let to_client_meta (data : t) : Oidc.Client.meta =
  Oidc.Client.make_meta ~client_name:data.name ~redirect_uris:[ redirect_uri ]
    ~contacts:[ "ulrik.strid@outlook.com" ]
    ~response_types:[ "code" ] ~grant_types:[ "authorization_code" ]
    ~token_endpoint_auth_method:"client_secret_post" ()

let metas = List.map to_client_meta datas

let get_clients ~kv ~make_store ~provider_uri =
  let open Lwt_result.Infix in
  List.map
    (fun data ->
      let store = make_store () in
      let meta = to_client_meta data in
      let uri = Uri.with_path provider_uri ("morph_auth_local/" ^ data.name) in
      let () = Logs.info (fun m -> m "%s" (Uri.to_string uri)) in
      OidcClient.make ~kv ~store
        ~redirect_uri:(Uri.of_string redirect_uri)
        ~provider_uri:uri ~client:(OidcClient.Register meta)
      >|= fun client -> (data, client))
    datas
  |> Lwt.all
