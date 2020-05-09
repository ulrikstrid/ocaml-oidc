type invalidPayload = [ | `Msg(string)];

type code = string;

type t =
  | Not_started
  | Authorizing(Parameters.t)
  | Interaction(Parameters.t)
  | Waiting_for_code(code, Jose.Jwt.t)
  | Invalid(invalidPayload);
