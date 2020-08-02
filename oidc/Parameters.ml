open Utils

type display = Page | Popup | Touch | Wap

let string_to_display = function
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
  redirect_uri : Uri.t;
  scope : string list;
  (* Must include at least the openid scope *)
  state : string option;
  nonce : string option;
  claims : Yojson.Safe.t option;
  max_age : int option;
  display : display option;
  prompt : prompt option;
}

let make ?(response_type = [ "code" ]) ?(scope = [ "openid" ]) ?state ?claims
    ?max_age ?display ?prompt ?nonce client ~redirect_uri =
  {
    response_type;
    client;
    redirect_uri;
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
        Some ("redirect_uri", [ Uri.to_string t.redirect_uri ]);
        Some ("scope", [ String.concat " " t.scope ]);
        Option.map (fun state -> ("state", [ state ])) t.state;
        Option.map (fun nonce -> ("nonce", [ nonce ])) t.nonce;
        Option.map
          (fun claims -> ("claims", [ Yojson.Safe.to_string claims ]))
          t.claims;
      ]
    |> List.filter_map identity |> Uri.encoded_of_query )

type parse_state =
  | Invalid of string
  | UnauthorizedClient of Client.t
  | InvalidScope of Client.t
  | InvalidWithClient of Client.t
  | InvalidWithRedirectUri of string
  | Valid of t

let get_client ~clients ~client_id =
  List.find_opt (fun (client : Client.t) -> client.id == client_id) clients
  |> function
  | Some client -> Ok client
  | None -> Error "No client found"

let parse_query ~clients uri =
  let getQueryParam param =
    Uri.get_query_param uri param |> function
    | Some x -> Ok x
    | None -> Error () |> Result.map_error (fun _ -> param ^ " not found")
  in

  let claims =
    getQueryParam "claims" |> Result.map Yojson.Safe.from_string |> function
    | Ok x -> Some x
    | Error _ -> None
  in

  let response_type =
    getQueryParam "response_type" |> Result.map (String.split_on_char ' ')
    |> function
    | Ok response_type ->
        if List.exists (fun rt -> rt == "code") response_type then
          Ok response_type
        else Error "response_type doesn't include code"
    | Error x -> Error x
  in

  let redirect_uri = getQueryParam "redirect_uri" in

  let client =
    getQueryParam "client_id"
    |> RResult.flat_map (fun client_id -> get_client ~clients ~client_id)
  in

  let scope = getQueryParam "scope" |> Result.map (String.split_on_char ' ') in

  let max_age =
    getQueryParam "max_age" |> ROpt.of_result |> ROpt.flat_map int_of_string_opt
  in

  match (client, response_type, redirect_uri, scope) with
  | Ok client, Ok response_type, Ok redirect_uri, Ok scope
    when List.exists
           (fun uri -> Uri.to_string uri = redirect_uri)
           client.redirect_uris ->
      Valid
        {
          response_type;
          client;
          redirect_uri = Uri.of_string redirect_uri;
          scope;
          state = ROpt.of_result (getQueryParam "state");
          nonce = ROpt.of_result (getQueryParam "nonce");
          claims;
          max_age;
          display =
            RResult.flat_map string_to_display (getQueryParam "display")
            |> ROpt.of_result;
          prompt =
            RResult.flat_map string_to_prompt_opt (getQueryParam "prompt")
            |> ROpt.of_result;
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
