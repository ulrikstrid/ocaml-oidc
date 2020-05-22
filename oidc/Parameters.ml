type display = Page | Popup | Touch | Wap

let string_to_display_opt = function
  | "page" -> Ok Page
  | "popup" -> Ok Popup
  | "touch" -> Ok Touch
  | "wap" -> Ok Wap
  | _ -> Error "Invalid display string"

type prompt = None | Login | Consent | Select_account

let string_to_prompt_opt = function
  | "none" -> Ok None
  | "login" -> Ok Login
  | "consent" -> Ok Consent
  | "select_account" -> Ok Select_account
  | _ -> Error "Invalid prompt string"

type t = {
  response_type : string list;
  client : Client.t;
  redirect_uri : string;
  scope : string list;
  (* Must include at least the openid scope *)
  state : string option;
  nonce : string;
  claims : Yojson.Basic.t option;
  max_age : int option;
  display : display option;
  prompt : prompt option;
}

let make ?(response_type = [ "code" ]) ?(scope = [ "openid" ]) ?state ?claims
    ?max_age ?display ?prompt client ~nonce ~redirect_uri =
  {
    response_type;
    client;
    redirect_uri = Uri.to_string redirect_uri;
    scope;
    state;
    nonce;
    claims;
    max_age;
    display;
    prompt;
  }

let identity a = a

let to_query t =
  "?"
  ^ ( [
        Some ("response_type", t.response_type);
        Some ("client_id", [ t.client.id ]);
        Some ("redirect_uri", [ t.redirect_uri ]);
        Some ("scope", [ CCString.concat " " t.scope ]);
        CCOpt.map (fun state -> ("state", [ state ])) t.state;
        Some ("nonce", [ t.nonce ]);
        CCOpt.map
          (fun claims -> ("claims", [ Yojson.Basic.to_string claims ]))
          t.claims;
      ]
    |> CCList.filter_map identity |> Uri.encoded_of_query )

type parse_state =
  | Invalid of string
  | UnauthorizedClient of Client.t
  | InvalidScope of Client.t
  | InvalidWithClient of Client.t
  | InvalidWithRedirectUri of string
  | Valid of t

let get_client ~clients ~client_id =
  CCList.find_opt (fun (client : Client.t) -> client.id == client_id) clients
  |> function
  | Some client -> Ok client
  | None -> Error "No client found"

let parse_query ~clients uri =
  let getQueryParam param =
    Uri.get_query_param uri param
    |> CCResult.of_opt
    |> CCResult.map_err (fun _ -> param ^ " not found")
  in

  let claims =
    getQueryParam "claims"
    |> CCResult.map Yojson.Basic.from_string
    |> CCOpt.of_result
  in

  let response_type =
    getQueryParam "response_type"
    |> CCResult.map (String.split_on_char ' ')
    |> CCResult.flat_map (fun response_type ->
           if CCList.exists (fun rt -> rt == "code") response_type then
             Ok response_type
           else Error "response_type doesn't include code")
  in

  let redirect_uri = getQueryParam "redirect_uri" in

  let client =
    getQueryParam "client_id"
    |> CCResult.flat_map (fun client_id -> get_client ~clients ~client_id)
  in

  let scope =
    getQueryParam "scope" |> CCResult.map (String.split_on_char ' ')
  in

  let max_age =
    getQueryParam "max_age" |> CCOpt.of_result |> CCOpt.flat_map CCInt.of_string
  in

  match (client, response_type, redirect_uri, scope) with
  | Ok client, Ok response_type, Ok redirect_uri, Ok scope
    when List.exists (fun uri -> uri == redirect_uri) client.redirect_uris ->
      Valid
        {
          response_type;
          client;
          redirect_uri;
          scope;
          state = CCOpt.of_result (getQueryParam "state");
          nonce = CCResult.get_or ~default:"12345" (getQueryParam "nonce");
          claims;
          max_age;
          display =
            CCResult.flat_map string_to_display_opt (getQueryParam "display")
            |> CCOpt.of_result;
          prompt =
            CCResult.flat_map string_to_prompt_opt (getQueryParam "prompt")
            |> CCOpt.of_result;
        }
  | Ok client, Ok _, _, Ok _ -> UnauthorizedClient client
  | Ok client, Error _e, _, _ -> InvalidWithClient client
  | Ok client, _, _, Error _ -> InvalidScope client
  | _, _, Ok redirect_uri, _ -> InvalidWithRedirectUri redirect_uri
  | Error client_id_msg, Ok _, Error redirect_uri_msg, _ ->
      Invalid (String.concat ", " [ client_id_msg; redirect_uri_msg ])
  | Error client_id_msg, Error response_type_msg, Error redirect_uri_msg, _ ->
      Invalid
        (String.concat ", "
           [ client_id_msg; response_type_msg; redirect_uri_msg ])
