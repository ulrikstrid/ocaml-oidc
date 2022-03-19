type t =
  [ `OpenID
  | `Profile
  | `Email
  | `Address
  | `Phone
  | `Offline_access
  | `S of string ]

let of_string = function
  | "openid" -> `OpenID
  | "profile" -> `Profile
  | "email" -> `Email
  | "address" -> `Address
  | "phone" -> `Phone
  | "offline_access" -> `Offline_access
  | non_standard -> `S non_standard

let to_string = function
  | `OpenID -> "openid"
  | `Profile -> "profile"
  | `Email -> "email"
  | `Address -> "address"
  | `Phone -> "phone"
  | `Offline_access -> "offline_access"
  | `S s -> s

let of_scope_parameter parameter =
  String.split_on_char ' ' parameter |> List.map of_string

let to_scope_parameter scopes = List.map to_string scopes |> String.concat " "
