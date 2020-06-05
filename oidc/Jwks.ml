let get_use jwk =
  match jwk with Jose.Jwk.Rsa_pub jwk -> jwk.use | Jose.Jwk.Oct jwk -> jwk.use

let matching_jwt (jwt : Jose.Jwt.t) (jwk : Jose.Jwk.public Jose.Jwk.t) =
  Jose.Jwk.get_alg jwk = jwt.header.alg && get_use jwk = `Sig

let find_jwk ~(jwt : Jose.Jwt.t) jwks =
  match jwt.header.kid with
  | Some kid ->
      Jose.Jwks.find_key jwks kid
      (* If there is no kid supplied well try with the first RSA signing key *)
  | None ->
      let matching_keys = List.filter (matching_jwt jwt) jwks.keys in
      if List.length matching_keys = 1 then Some (List.hd matching_keys)
      else None
