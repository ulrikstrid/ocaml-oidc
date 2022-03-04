(** Generic Key/Value store for caching etc *)

module type KV = sig
  type value
  type store

  val get : store:store -> string -> (value, [> `Msg of string]) Lwt_result.t
  val set : ?expiry:int -> store:store -> string -> value -> unit Lwt.t
end

module MemoryKV : sig
  type value = string
  type store = (string, string) Hashtbl.t

  val get : store:store -> string -> (value, [> `Msg of string]) Lwt_result.t
  val set : ?expiry:int -> store:store -> string -> value -> unit Lwt.t
end
