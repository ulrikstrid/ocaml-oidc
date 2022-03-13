(** https://openid.net/specs/openid-connect-basic-1_0.html#Scopes *)

type t =
  [ `OpenID
    (** REQUIRED. Informs the Authorization Server that the Client is making an OpenID Connect request. If the openid scope value is not present, the behavior is entirely unspecified.  *)
  | `Profile
    (** OPTIONAL. This scope value requests access to the End-User's default profile Claims, which are: name, family_name, given_name, middle_name, nickname, preferred_username, profile, picture, website, gender, birthdate, zoneinfo, locale, and updated_at. *)
  | `Email
    (** OPTIONAL. This scope value requests access to the email and email_verified Claims. *)
  | `Address
    (** OPTIONAL. This scope value requests access to the address Claim. *)
  | `Phone
    (** OPTIONAL. This scope value requests access to the phone_number and phone_number_verified Claims. *)
  | `Offline_access
    (** OPTIONAL. This scope value requests that an OAuth 2.0 Refresh Token be issued that can be used to obtain an Access Token that grants access to the End-User's UserInfo Endpoint even when the End-User is not present (not logged in). *)
  | `S of string ]
(** REQUIRED and optional are just for OpenID connect, OAuth2 doesn't have any defiend scopes *)

val of_string : string -> t
val to_string : t -> string
val of_scope_parameter : string -> t list
val to_scope_parameter : t list -> string