module type KV = sig
  type value

  type store

  val get : store:store -> string -> (value, [> `Msg of string ]) Lwt_result.t

  val set : ?expiry:int -> store:store -> string -> value -> unit Lwt.t
end

module MemoryKV :
  KV with type value = string and type store = (string, string) Hashtbl.t =
struct
  type value = string

  type store = (string, string) Hashtbl.t

  let of_option = function
    | Some value -> Lwt_result.return value
    | None -> Lwt_result.fail (`Msg "Not found")

  let get ~(store : (string, 'value) Hashtbl.t) key =
    Hashtbl.find_opt store key |> of_option

  let set ?expiry:_ ~(store : (string, 'value) Hashtbl.t) key (value : 'value) =
    Hashtbl.add store key value |> Lwt.return
end
