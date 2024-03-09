open Utils

type t = {
  grant_type : string;
  scope : Scopes.t list;
  refresh_token : string;
  client_id : string;
  client_secret : string option;
  redirect_uri : Uri.t;
}

let make ~grant_type ~scope ~redirect_uri ~refresh_token client =
  let { Client.id; secret; _ } = client in
  {
    grant_type;
    scope;
    refresh_token;
    client_id = id;
    client_secret = secret;
    redirect_uri;
  }

let to_body_string t =
  [
    ("grant_type", [t.grant_type]);
    ("scope", [Scopes.to_scope_parameter t.scope]);
    ("refresh_token", [t.refresh_token]);
    ("client_id", [t.client_id]);
    ("client_secret", [t.client_secret |> ROpt.get_or ~default:"secret"]);
    ("redirect_uri", [t.redirect_uri |> Uri.to_string]);
  ]
  |> Uri.encoded_of_query

(* The Authorization Server MUST validate the Token Request as follows:

   Authenticate the Client if it was issued Client Credentials or if it uses another Client Authentication method, per Section 9.
   Ensure the Authorization Code was issued to the authenticated Client.
   Verify that the Authorization Code is valid.
   If possible, verify that the Authorization Code has not been previously used.
   Ensure that the redirect_uri parameter value is identical to the redirect_uri parameter value that was included in the initial Authorization Request. If the redirect_uri parameter value is not present when there is only one registered redirect_uri value, the Authorization Server MAY return an error (since the Client should have included the parameter) or MAY proceed without an error (since OAuth 2.0 permits the parameter to be omitted in this case).
   Verify that the Authorization Code used was issued in response to an OpenID Connect Authentication Request (so that an ID Token will be returned from the Token Endpoint).
*)

let of_body_string body =
  let query = Uri.query_of_encoded body |> Uri.with_query Uri.empty in
  let gt = Uri.get_query_param query "grant_type" in
  let s = Uri.get_query_param query "scope" in
  let rt = Uri.get_query_param query "refresh_token" in
  let ci = Uri.get_query_param query "client_id" in
  let client_secret = Uri.get_query_param query "client_secret" in
  let ru = Uri.get_query_param query "redirect_uri" in
  match (gt, s, rt, ci, ru) with
  | Some grant_type, Some scope, Some refresh_token, Some client_id, Some redirect_uri ->
    Ok
      {
        grant_type;
        scope = Scopes.of_scope_parameter scope;
        refresh_token;
        client_id;
        client_secret;
        redirect_uri = redirect_uri |> Uri.of_string;
      }
  | Some grant_type, None, Some refresh_token, Some client_id, Some redirect_uri ->
    Ok
      {
        grant_type;
        scope = [];
        refresh_token;
        client_id;
        client_secret;
        redirect_uri = redirect_uri |> Uri.of_string;
      }
  | Some _, Some _, Some _, Some _, None -> Error (`Msg "missing redirect_uri")
  | Some _, Some _, Some _, None, Some _ -> Error (`Msg "missing client_id")
  | Some _, Some _, None, Some _, Some _ -> Error (`Msg "missing refresh_token")
  | None, Some _, Some _, Some _, Some _ -> Error (`Msg "missing grant_type")
  | _ -> Error (`Msg "More than 1 missing")

