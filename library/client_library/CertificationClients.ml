type t = {
  name : string;
  category : string;
  description : string;
  info : string;
  provider_uri : string;
}

let redirect_uri =
  try Sys.getenv "OIDC_REDIRECT_URI"
  with _ -> failwith "Must set OIDC_REDIRECT_URI"

let form_post_certification_client_data =
  let provider_uri =
    try Sys.getenv "FORM_POST_PROVIDER_HOST"
    with _ -> failwith "Must set FORM_POST_PROVIDER_HOST"
  in
  {
    name = "form_post_morph_oidc_client";
    category = "new";
    description = "Form Post";
    info = "the new certification";
    provider_uri;
  }

let basic_certification_client_data =
  let provider_uri =
    try Sys.getenv "BASIC_PROVIDER_HOST"
    with _ -> failwith "Must set BASIC_PROVIDER_HOST"
  in
  {
    name = "basic_morph_oidc_client";
    category = "new";
    description = "Form Post";
    info = "the new certification";
    provider_uri;
  }

let to_client_meta (data : t) : Oidc.Client.meta =
  Oidc.Client.make_meta ~client_name:data.name
    ~redirect_uris:
      (List.map Uri.of_string [redirect_uri; data.provider_uri ^ "/callback"])
    ~contacts:["ulrik.strid@outlook.com"]
    ~response_types:["code"] ~grant_types:["authorization_code"]
    ~token_endpoint_auth_method:"client_secret_basic" ()

let datas : t list =
  [form_post_certification_client_data; basic_certification_client_data]

let get_clients ~kv ~make_store =
  let open Lwt_result.Infix in
  List.map
    (fun data ->
      let store = make_store () in
      let meta = to_client_meta data in
      let uri = Uri.of_string data.provider_uri in
      let () =
        Logs.info (fun m ->
            m "Creating client for provider with uri: %s" data.provider_uri)
      in
      OidcClient.Dynamic.make ~kv ~store ~provider_uri:uri meta
      >|= fun client -> (data, client))
    datas
  |> Lwt.all
