let src =
  Logs.Src.create "oidc.jwks" ~doc:"logs OIDC events in the IDToken module"

module Log = (val Logs.src_log src : Logs.LOG)

let get_use jwk =
  match jwk with
  | Jose.Jwk.Rsa_pub jwk -> jwk.use
  | Jose.Jwk.Oct jwk -> jwk.use
  | Jose.Jwk.Es256_pub jwk -> jwk.use
  | Jose.Jwk.Es384_pub jwk -> jwk.use
  | Jose.Jwk.Es512_pub jwk -> jwk.use
  | Jose.Jwk.Ed25519_pub jwk -> jwk.use

let matching_jwt (jwt : Jose.Jwt.t) (jwk : Jose.Jwk.public Jose.Jwk.t) =
  match (Jose.Jwk.get_alg jwk, get_use jwk) with
  | Some alg, Some use -> alg = jwt.header.alg && use = `Sig
  | _, _ -> false

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
    if List.length matching_keys = 1 then Some (List.hd matching_keys) else None
