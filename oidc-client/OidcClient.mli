type 'store t = {
  kv : (module KeyValue.KV with type value = string and type store = 'store);
  store : 'store;
  client : Oidc.Client.t;
  http_client : Piaf.Client.t;
  provider_uri : Uri.t;
  redirect_uri : Uri.t;
}
(** A OIDC Client*)

(** {2 Startup}

    The following are things you might want to do when you start the server
*)

val make :
  kv:(module KeyValue.KV with type store = 'store and type value = string) ->
  store:'store ->
  ?http_client:Piaf.Client.t ->
  redirect_uri:Uri.t ->
  provider_uri:Uri.t ->
  client:Oidc.Client.t ->
  ('store t, Piaf.Error.t) result Lwt.t
(** Creates a [t] with the supplied store type *)

val discover : 'store t -> (Oidc.Discover.t, Piaf.Error.t) result Lwt.t
(** Get the provider discovery document *)

val get_jwks : 'store t -> (Jose.Jwks.t, Piaf.Error.t) result Lwt.t
(** Get JWKs from the provider *)

(** {2 Authentication start}

    These functions are typically used when initiating the login.

    You want to save nonce and state somewhere to use when the user returns and you validate the token.
    This is typically done via session storage.
*)

val get_auth_uri :
  ?scope:string list ->
  ?claims:Yojson.Safe.t ->
  ?nonce:string ->
  state:string ->
  'store t ->
  (string, Piaf.Error.t) result Lwt.t
(** Create a valid auth uri that can be used redirect the user to the OIDC Provider *)

(** {2 Authentication callback}

    These functions are used when the user returns to the RP with a code from the Provider.
*)

val get_and_validate_id_token :
  ?nonce:string ->
  code:string ->
  'store t ->
  (Oidc.TokenResponse.t, Oidc.IDToken.validation_error) result Lwt.t
(** Get a token response from the token endpoint and validate the ID Token. *)

val get_token :
  code:string -> 'store t -> (Oidc.TokenResponse.t, Piaf.Error.t) result Lwt.t
(** Get a token response from the token endpoint, consider using [get_and_validate_id_token] instead. *)

val get_userinfo :
  jwt:Jose.Jwt.t ->
  token:string ->
  'a t ->
  (string, [> `Missing_sub | `Msg of string | `Sub_missmatch ]) result Lwt.t
(** Get the userinfo data with the access_token returned in the token response. *)

module Dynamic : sig
  (** {1 Dynamic registration } *)

  (**
    All functions in this module maps to the base functions but will create a Client "just in time" and make sure you always have a fresh Client to work with.
    *)

  type 'store t = {
    kv : (module KeyValue.KV with type value = string and type store = 'store);
    store : 'store;
    http_client : Piaf.Client.t;
    meta : Oidc.Client.meta;
    provider_uri : Uri.t;
  }
  (** A Dynamically registered OIDC Client *)

  val make :
    kv:(module KeyValue.KV with type store = 'store and type value = string) ->
    store:'store ->
    provider_uri:Uri.t ->
    Oidc.Client.meta ->
    ('store t, Piaf.Error.t) result Lwt.t

  val register :
    'store t ->
    Oidc.Client.meta ->
    (Oidc.Client.dynamic_response, Piaf.Error.t) result Lwt.t
  (** Register a dynamic client, this will mostly be handled for you automatically but can be useful *)

  val get_jwks : 'store t -> (Jose.Jwks.t, Piaf.Error.t) result Lwt.t

  val get_token :
    code:string -> 'store t -> (Oidc.TokenResponse.t, Piaf.Error.t) result Lwt.t

  val get_auth_parameters :
    ?scope:string list ->
    ?claims:Yojson.Safe.t ->
    nonce:string ->
    state:string ->
    'store t ->
    (Oidc.Parameters.t, [> `Msg of string ]) result Lwt.t

  val get_auth_uri :
    ?scope:string list ->
    ?claims:Yojson.Safe.t ->
    nonce:string ->
    state:string ->
    'store t ->
    (string, Piaf.Error.t) result Lwt.t

  val get_and_validate_id_token :
    ?nonce:string ->
    code:string ->
    'store t ->
    (Oidc.TokenResponse.t, Oidc.IDToken.validation_error) result Lwt.t

  val get_auth_result :
    nonce:string ->
    params:(string * string list) list ->
    state:string ->
    'a t ->
    (Oidc.TokenResponse.t, Oidc.IDToken.validation_error) result Lwt.t

  val get_userinfo :
    jwt:Jose.Jwt.t ->
    token:string ->
    'a t ->
    (string, [> `Missing_sub | `Msg of string | `Sub_missmatch ]) result Lwt.t
end

module KeyValue = KeyValue

module Microsoft : sig
  (** {1 Microsft Azure AD } 

    Convenience module to work with Microsft Azure AD
    *)

  val make :
    kv:(module KeyValue.KV with type store = 'store and type value = string) ->
    store:'store ->
    app_id:string ->
    tenant_id:'a ->
    secret:string option ->
    redirect_uri:Uri.t ->
    ?http_client:Piaf.Client.t ->
    ('store t, Piaf.Error.t) result Lwt.t
  (** Creates a static Client configured for Microsft Azure AD *)
end
