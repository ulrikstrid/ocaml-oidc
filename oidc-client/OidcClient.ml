include StaticClient

module Microsoft = struct
  let make (type store)
      ~(kv :
         (module KeyValue.KV with type value = string and type store = store))
      ~(store : store) ~app_id ~tenant_id:_ ~secret ~redirect_uri =
    let provider_uri =
      Uri.of_string "https://login.microsoftonline.com/common/v2.0"
    in
    let client : Oidc.Client.t =
      {
        id = app_id;
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        redirect_uris = [ "https://login.microsoftonline.com/common/v2.0" ];
        secret;
        token_endpoint_auth_method = "client_secret_post";
      }
    in
    make ~kv ~store ~redirect_uri ~provider_uri ~client
end

module Dynamic = DynamicClient
module KeyValue = KeyValue
