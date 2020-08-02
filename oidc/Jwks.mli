(** JSON Web Keys *)

val find_jwk :
  jwt:Jose.Jwt.t -> Jose.Jwks.t -> Jose.Jwk.public Jose.Jwk.t option
(** find_jwk wraps {! Jose.Jwks.find_key } but if there is no [kid] supplied it will try with the first RSA signing key 

    This helps us with the certification test [rp-id_token-kid-absent-single-jwks] *)
