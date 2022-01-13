module ROpt = struct
  let of_result = function Ok x -> Some x | Error _ -> None
  let flat_map fn = function Some x -> fn x | None -> None
  let map_or ~default fn = function Some x -> fn x | None -> default
  let get_or ~default = function Some x -> x | None -> default
end

module RResult = struct
  let of_option = function Some x -> Ok x | None -> Error (`Msg "None")
  let flat_map fn = function Error x -> Error x | Ok x -> fn x
  let ( >|= ) e f = Result.map f e
  let ( >>= ) e f = flat_map f e
end

module RPiaf = struct
  let map_piaf_err (x : ('a, Piaf.Error.t) Lwt_result.t) :
      ('a, [> `Msg of string]) Lwt_result.t =
    Lwt_result.map_err (fun e -> `Msg (Piaf.Error.to_string e)) x
end

let src = Logs.Src.create "oidc_client" ~doc:"logs OIDC Client events"

module Log = (val Logs.src_log src : Logs.LOG)
