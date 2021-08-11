type t = {
  id : string;
  response_types : string list;
  grant_types : string list;
  redirect_uris : Uri.t list;
  secret : string option;
  token_endpoint_auth_method : string;
}

let make ?secret ~response_types ~grant_types ~redirect_uris
    ~token_endpoint_auth_method id =
  {
    id;
    response_types;
    grant_types;
    redirect_uris;
    token_endpoint_auth_method;
    secret;
  }
