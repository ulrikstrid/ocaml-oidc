open Utils

type error =
  [ `Unauthorized_client of Client.t
  | `Missing_client
  | `Invalid_scope of string list
  | `Invalid_redirect_uri of string
  | `Missing_parameter of string
  | `Invalid_display of string
  | `Invalid_prompt of string
  | `Invalid_parameters
  ]

module Display = struct
  type t =
    [ `Page
    | `Popup
    | `Touch
    | `Wap
    ]

  type error = [ `Invalid_display of string ]

  let parse = function
    | "page" -> Ok `Page
    | "popup" -> Ok `Popup
    | "touch" -> Ok `Touch
    | "wap" -> Ok `Wap
    | s -> Error (`Invalid_display s)

  let serialize = function
    | `Page -> "page"
    | `Popup -> "popup"
    | `Touch -> "touch"
    | `Wap -> "wap"
end

module Prompt = struct
  type t =
    [ `None
    | `Login
    | `Consent
    | `Select_account
    ]

  type error = [ `Invalid_prompt of string ]

  let parse = function
    | "none" -> Ok `None
    | "login" -> Ok `Login
    | "consent" -> Ok `Consent
    | "select_account" -> Ok `Select_account
    | s -> Error (`Invalid_prompt s)

  let serialize = function
    | `None -> "none"
    | `Login -> "login"
    | `Consent -> "consent"
    | `Select_account -> "select_account"
end

type t =
  { response_type : string list
  ; (* TODO: This should probably just be a string *)
    client_id : string
  ; redirect_uri : Uri.t
  ; scope : Scopes.t list
  ; (* Must include at least the openid scope *)
    state : string option
  ; nonce : string option
  ; claims : Yojson.Safe.t option
  ; max_age : int option
  ; display : Display.t option
  ; prompt : Prompt.t option
  }

let make
      ?(response_type = [ "code" ])
      ?(scope = [ `OpenID ])
      ?state
      ?claims
      ?max_age
      ?display
      ?prompt
      ?nonce
      ~redirect_uri
      ~client_id
      ()
  =
  { response_type
  ; client_id
  ; redirect_uri
  ; scope
  ; state
  ; nonce
  ; claims
  ; max_age
  ; display
  ; prompt
  }

let identity a = a

let to_query t =
  [ Some ("response_type", t.response_type)
  ; Some ("client_id", [ t.client_id ])
  ; Some ("redirect_uri", [ Uri.to_string t.redirect_uri ])
  ; Some ("scope", [ Scopes.to_scope_parameter t.scope ])
  ; Option.map (fun state -> "state", [ state ]) t.state
  ; Option.map (fun nonce -> "nonce", [ nonce ]) t.nonce
  ; Option.map
      (fun claims -> "claims", [ Yojson.Safe.to_string claims ])
      t.claims
  ; Option.map (fun prompt -> "prompt", [ Prompt.serialize prompt ]) t.prompt
  ; Option.map
      (fun display -> "display", [ Display.serialize display ])
      t.display
  ]
  |> List.filter_map identity

let to_yojson t : Yojson.Safe.t =
  `Assoc
    ([ Some
         ( "response_type"
         , `List (t.response_type |> List.map (fun r -> `String r)) )
     ; Some ("client_id", `String t.client_id)
     ; Some ("redirect_uri", `String (Uri.to_string t.redirect_uri))
     ; Some
         ( "scope"
         , `List (t.scope |> List.map (fun r -> `String (Scopes.to_string r)))
         )
     ; Option.map (fun state -> "state", `String state) t.state
     ; Option.map (fun nonce -> "nonce", `String nonce) t.nonce
     ; Option.map (fun claims -> "claims", claims) t.claims
     ; Option.map
         (fun prompt -> "prompt", `String (Prompt.serialize prompt))
         t.prompt
     ; Option.map
         (fun display -> "display", `String (Display.serialize display))
         t.display
     ]
    |> List.filter_map identity)

let of_yojson json : (t, [> error ]) result =
  let module Json = Yojson.Safe.Util in
  try
    Ok
      { response_type =
          Json.to_list (Json.member "response_type" json)
          |> List.map Json.to_string
      ; client_id = Json.member "client_id" json |> Json.to_string
      ; redirect_uri =
          json |> Json.member "redirect_uri" |> Json.to_string |> Uri.of_string
      ; scope =
          json
          |> Json.member "scope"
          |> Json.to_list
          |> List.map (fun s -> Scopes.of_string @@ Json.to_string s)
      ; state = json |> Json.member "state" |> Json.to_string_option
      ; nonce = json |> Json.member "nonce" |> Json.to_string_option
      ; claims = json |> Json.member "claims" |> Option.some
      ; max_age = json |> Json.member "max_age" |> Json.to_int_option
      ; display =
          json
          |> Json.member "display"
          |> Json.to_string_option
          |> ROpt.flat_map (fun d -> Display.parse d |> ROpt.of_result)
      ; prompt =
          json
          |> Json.member "prompt"
          |> Json.to_string_option
          |> ROpt.flat_map (fun p -> Prompt.parse p |> ROpt.of_result)
      }
  with
  | _ -> Error `Invalid_parameters

let parse_query uri : (t, [> error ]) result =
  let getQueryParam param =
    Uri.get_query_param uri param |> function
    | Some x -> Ok x
    | None -> Error (`Missing_parameter (param ^ " not found"))
  in

  match getQueryParam "client_id" with
  | Error e -> Error e
  | Ok client_id ->
    let claims =
      getQueryParam "claims" |> Result.map Yojson.Safe.from_string |> function
      | Ok x -> Some x
      | Error _ -> None
    in

    let response_type =
      getQueryParam "response_type" |> Result.map (String.split_on_char ' ')
    in

    let redirect_uri = getQueryParam "redirect_uri" in

    let scope =
      getQueryParam "scope" |> Result.map Scopes.of_scope_parameter
      (* TODO: Check for openid *)
    in

    let max_age =
      getQueryParam "max_age"
      |> ROpt.of_result
      |> ROpt.flat_map int_of_string_opt
    in

    (match response_type, redirect_uri, scope with
    | Ok response_type, Ok redirect_uri, Ok scope ->
      Ok
        { response_type
        ; client_id
        ; redirect_uri = Uri.of_string redirect_uri
        ; scope
        ; state = ROpt.of_result (getQueryParam "state")
        ; nonce = ROpt.of_result (getQueryParam "nonce")
        ; claims
        ; max_age
        ; display =
            RResult.flat_map Display.parse (getQueryParam "display")
            |> ROpt.of_result
        ; prompt =
            RResult.flat_map Prompt.parse (getQueryParam "prompt")
            |> ROpt.of_result
        }
    | Error e, _, _ -> Error e
    | _, Error e, _ -> Error e
    | _, _, Error e -> Error e)
