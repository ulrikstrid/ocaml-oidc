type t =
  { host : string
  ; issuer : Uri.t
  }

let make host issuer = { host; issuer }

let of_yojson json =
  let module Json = Yojson.Safe.Util in
  { host = Json.member "host" json |> Json.to_string
  ; issuer = Json.member "issuer" json |> Json.to_string |> Uri.of_string
  }
