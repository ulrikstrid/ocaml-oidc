module RJson = struct
  let to_json_string_opt key value =
    match value with Some s -> Some (key, `String s) | None -> None
end

module RResult = struct
  let of_option = function Some x -> Ok x | None -> Error (`Msg "None")

  let flat_map fn = function Error x -> Error x | Ok x -> fn x

  let ( >|= ) e f = Result.map f e

  let ( >>= ) e f = flat_map f e
end

module ROpt = struct
  let of_result = function Ok x -> Some x | Error _ -> None

  let flat_map fn = function Some x -> fn x | None -> None

  let map_or ~default fn = function Some x -> fn x | None -> default

  let get_or ~default = function Some x -> x | None -> default
end

module RBase64 = struct
  let encode_string str =
    Base64.encode_string ~alphabet:Base64.default_alphabet str
end

module RString = struct
  let replace ~sub ~by str =
    Astring.String.cuts ~empty:false ~sep:sub str
    |> Astring.String.concat ~sep:by
end

let src = Logs.Src.create "oidc" ~doc:"logs OIDC events"

module Log = (val Logs.src_log src : Logs.LOG)
