let src =
  Logs.Src.create "oidc.jwks" ~doc:"logs OIDC events in the IDToken module"

module Log = (val Logs.src_log src : Logs.LOG)

let _get_use jwk =
  match jwk with
  | Jose.Jwk.Rsa_pub jwk -> jwk.use
  | Jose.Jwk.Oct jwk -> jwk.use
  | Jose.Jwk.Es256_pub jwk -> jwk.use
  | Jose.Jwk.Es384_pub jwk -> jwk.use
  | Jose.Jwk.Es512_pub jwk -> jwk.use
  | Jose.Jwk.Ed25519_pub jwk -> jwk.use

let get_alg jwk =
  match jwk with
  | Jose.Jwk.Rsa_pub _jwk -> `RS256
  | Jose.Jwk.Oct _jwk -> `HS256
  | Jose.Jwk.Es256_pub _jwk -> `ES256
  | Jose.Jwk.Es384_pub _jwk -> `ES384
  | Jose.Jwk.Es512_pub _jwk -> `ES512
  | Jose.Jwk.Ed25519_pub _jwk -> `EdDSA

let matching_jwt (jwt : Jose.Jwt.t) (jwk : Jose.Jwk.public Jose.Jwk.t) =
  get_alg jwk = jwt.header.alg

let find_jwk ~(jwt : Jose.Jwt.t) jwks =
  match jwt.header.kid with
  | Some kid ->
    Jose.Jwks.find_key jwks kid
    (* If there is no kid supplied we'll try with the first RSA signing key *)
  | None ->
    Log.debug (fun m ->
        m "No kid supplied, trying the first key with matching alg")
    [@coverage off];
    let matching_keys = List.filter (matching_jwt jwt) jwks.keys in
    match matching_keys with
    | key :: _ -> Some key
    | [] -> None

