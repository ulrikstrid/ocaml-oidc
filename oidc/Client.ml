type t =
  { id : string
  ; response_types : string list
  ; grant_types : string list
  ; redirect_uris : Uri.t list
  ; secret : string option
  ; token_endpoint_auth_method : string
  }

let make
      ?secret
      ~response_types
      ~grant_types
      ~redirect_uris
      ~token_endpoint_auth_method
      id
  =
  { id
  ; response_types
  ; grant_types
  ; redirect_uris
  ; token_endpoint_auth_method
  ; secret
  }

type meta =
  { redirect_uris : Uri.t list
  ; response_types : string list option
  ; grant_types : string list option
  ; application_type : string option
  ; contacts : string list option
  ; client_name : string option
  ; token_endpoint_auth_method : string option
  ; logo_uri : Uri.t option
  ; client_uri : Uri.t option
  ; policy_uri : Uri.t option
  ; tos_uri : Uri.t option
  ; jwks_uri : Uri.t option
  ; sector_identifier_uri : Uri.t option
  ; subject_type : string option
  ; id_token_signed_response_alg : Jose.Jwa.alg option
  }

let make_meta
      ?(response_types : string list option)
      ?(grant_types : string list option)
      ?(application_type : string option)
      ?(contacts : string list option)
      ?(client_name : string option)
      ?(token_endpoint_auth_method : string option)
      ?(logo_uri : Uri.t option)
      ?(client_uri : Uri.t option)
      ?(policy_uri : Uri.t option)
      ?(tos_uri : Uri.t option)
      ?(jwks_uri : Uri.t option)
      ?(sector_identifier_uri : Uri.t option)
      ?(subject_type : string option)
      ?(id_token_signed_response_alg : Jose.Jwa.alg option)
      ~(redirect_uris : Uri.t list)
      ()
  =
  { redirect_uris
  ; response_types
  ; grant_types
  ; application_type
  ; contacts
  ; client_name
  ; token_endpoint_auth_method
  ; logo_uri
  ; client_uri
  ; policy_uri
  ; tos_uri
  ; jwks_uri
  ; sector_identifier_uri
  ; subject_type
  ; id_token_signed_response_alg
  }

let meta_to_yojson meta =
  let open Utils in
  let values =
    [ Some
        ( "redirect_uris"
        , `List
            (List.map (fun s -> `String (Uri.to_string s)) meta.redirect_uris)
        )
    ; Option.map
        (fun response_types ->
           ( "response_types"
           , `List (List.map (fun s -> `String s) response_types) ))
        meta.response_types
    ; Option.map
        (fun grant_types ->
           "grant_types", `List (List.map (fun s -> `String s) grant_types))
        meta.grant_types
    ; RJson.to_yojson_string_opt "application_type" meta.application_type
    ; Option.map
        (fun contacts ->
           "contacts", `List (List.map (fun s -> `String s) contacts))
        meta.contacts
    ; RJson.to_yojson_string_opt "client_name" meta.client_name
    ; RJson.to_yojson_string_opt
        "token_endpoint_auth_method"
        meta.token_endpoint_auth_method
    ; RJson.to_yojson_string_opt
        "logo_uri"
        (Option.map Uri.to_string meta.logo_uri)
    ; RJson.to_yojson_string_opt
        "client_uri"
        (Option.map Uri.to_string meta.client_uri)
    ; RJson.to_yojson_string_opt
        "policy_uri"
        (Option.map Uri.to_string meta.policy_uri)
    ; RJson.to_yojson_string_opt
        "tos_uri"
        (Option.map Uri.to_string meta.tos_uri)
    ; RJson.to_yojson_string_opt
        "jwks_uri"
        (Option.map Uri.to_string meta.jwks_uri)
    ; RJson.to_yojson_string_opt
        "sector_identifier_uri"
        (Option.map Uri.to_string meta.sector_identifier_uri)
    ; RJson.to_yojson_string_opt "subject_type" meta.subject_type
    ; RJson.to_yojson_string_opt
        "id_token_signed_response_alg"
        (Option.map Jose.Jwa.alg_to_string meta.id_token_signed_response_alg)
    ]
  in
  `Assoc (List.filter_map (fun x -> x) values)

let meta_to_string c =
  meta_to_yojson c
  |> Yojson.Safe.Util.to_assoc
  |> List.filter (function _, `Null -> false | _ -> true)
  |> fun l -> `Assoc l |> Yojson.Safe.to_string

type dynamic_response =
  { client_id : string
  ; client_secret : string option
  ; registration_access_token : string option
  ; registration_client_uri : string option
  ; client_secret_expires_at : int option
  ; client_id_issued_at : int option
  ; client_id_expires_at : int option
  ; application_type : string option
  }

let dynamic_is_expired dynamic =
  let now = Unix.time () |> int_of_float in
  match dynamic.client_id_expires_at with Some i -> i < now | None -> false

(* If it's not provided we assume it's valid forever *)

let dynamic_of_yojson (json : Yojson.Safe.t) : (dynamic_response, string) result
  =
  try
    let module Json = Yojson.Safe.Util in
    Ok
      { client_id = json |> Json.member "client_id" |> Json.to_string
      ; client_secret =
          json |> Json.member "client_secret" |> Json.to_string_option
      ; registration_access_token =
          json
          |> Json.member "registration_access_token"
          |> Json.to_string_option
      ; registration_client_uri =
          json |> Json.member "registration_client_uri" |> Json.to_string_option
      ; client_secret_expires_at =
          json |> Json.member "client_secret_expires_at" |> Json.to_int_option
      ; client_id_issued_at =
          json |> Json.member "client_id_issued_at" |> Json.to_int_option
      ; client_id_expires_at =
          json |> Json.member "client_id_expires_at" |> Json.to_int_option
      ; application_type =
          json |> Json.member "application_type" |> Json.to_string_option
      }
  with
  | Yojson.Safe.Util.Type_error (str, _) -> Error str

let dynamic_of_string response =
  Yojson.Safe.from_string response |> dynamic_of_yojson

let of_dynamic_and_meta ~dynamic ~meta =
  let open Utils in
  { id = dynamic.client_id
  ; redirect_uris = meta.redirect_uris
  ; secret = dynamic.client_secret
  ; grant_types = ROpt.get_or meta.grant_types ~default:[ "authorization_code" ]
  ; response_types = ROpt.get_or meta.response_types ~default:[ "code" ]
  ; token_endpoint_auth_method =
      ROpt.get_or meta.token_endpoint_auth_method ~default:"client_secret_post"
  }
