type invalidPayload = [ `Msg of string ]
type code = string

type t =
  | Not_started
  | Authorizing of Parameters.t
  | Interaction of Parameters.t
  | Waiting_for_code of code * Jose.Jwt.t
  | Invalid of invalidPayload
