(* https://openid.net/specs/openid-connect-core-1_0.html#IDToken *)
(* https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation *)

(*
  Required fields:
  - iss
  - sub - not longer than 256 ASCII chars
  - aud
  - exp
  - iat
  
  Fields to be validated if exists
  - nonce

  Optional fields:
  - acr
  - amr
  - azp (required if aud is a list)
*)
let ( >|= ) = CCResult.( >|= )

let ( >>= ) = CCResult.( >>= )

let get_string_member member payload =
  Yojson.Safe.Util.member member payload |> Yojson.Safe.Util.to_string_option

let get_int_member member payload =
  Yojson.Safe.Util.member member payload |> Yojson.Safe.Util.to_int_option

let validate_sub (jwt : Jose.Jwt.t) =
  match get_string_member "sub" jwt.payload with
  | Some sub when String.length sub < 257 -> Ok jwt
  | Some _sub -> Error `Invalid_sub_length
  | None -> Error `Missing_sub

let validate_exp (jwt : Jose.Jwt.t) =
  let module Json = Yojson.Safe.Util in
  match get_int_member "exp" jwt.payload with
  | Some exp when exp > int_of_float (Unix.time ()) -> Ok jwt
  | Some _exp -> Error `Expired
  | None -> Error `Missing_exp

let validate_iat (jwt : Jose.Jwt.t) =
  let now = int_of_float (Unix.time ()) in
  match get_int_member "iat" jwt.payload with
  | Some iat when iat <= now ->
      Ok jwt (* TODO: Make the time diff configurable *)
  | Some _iat -> Error `Iat_in_future
  | None -> Error `Missing_iat

let validate_iss ~issuer (jwt : Jose.Jwt.t) =
  match get_string_member "iss" jwt.payload with
  | Some iss when iss = issuer -> Ok jwt
  | Some iss -> Error (`Wrong_iss_value iss)
  | None -> Error `Missing_iss

let validate_aud ~(client : Client.t) (jwt : Jose.Jwt.t) =
  match Yojson.Safe.Util.member "aud" jwt.payload with
  | `String aud when aud = client.id -> Ok jwt
  | `String aud -> Error (`Wrong_aud_value aud)
  | `List json -> (
      let maybe_client_id =
        List.find_opt (fun v -> v = `String client.id) json
      in
      match maybe_client_id with
      | Some _ -> Ok jwt
      | None -> Error (`Wrong_aud_value "")
      (* TODO: Check azp as well if audience is longer than 1 *) )
  | _ -> Error `Missing_aud

let validate_nonce ?nonce (jwt : Jose.Jwt.t) =
  let () = CCOpt.iter print_endline nonce in
  let jwt_nonce = get_string_member "nonce" jwt.payload in
  match (nonce, jwt_nonce) with
  | Some nonce, Some jwt_nonce ->
      if nonce = jwt_nonce then Ok jwt else Error `Invalid_nonce
  | None, Some _ -> Error `Unexpected_nonce
  | Some _, None -> Error `Missing_nonce
  | None, None -> Ok jwt

let validate ?nonce ?jwk ~(client : Client.t) ~issuer (jwt : Jose.Jwt.t) =
  ( match (jwt.header.alg, jwk) with
  | `None, _ -> Ok jwt
  | _, Some jwk -> Jose.Jwt.validate ~jwk jwt
  | _, None -> Error `No_jwk_provided )
  >>= validate_iss ~issuer >>= validate_exp >>= validate_iat >>= validate_sub
  >>= validate_aud ~client >>= validate_nonce ?nonce
