let handler clients ({ request; _ } : Morph.Request.t) =
  let uri = Uri.of_string request.target in
  (match Oidc.Parameters.parse_query ~clients uri with
  | Ok _ -> Morph.Response.text "Valid"
  | Error `Unauthorized_client _ ->  Morph.Response.text "Unauthorized_client"
  | Error `Missing_client -> Morph.Response.text "Missing_client"
  | Error `Invalid_scope _ -> Morph.Response.text "Invalid_scope"
  | Error `Invalid_redirect_uri s -> Morph.Response.text ("Invalid_redirect_uri " ^ s)
  | Error `Missing_parameter s -> Morph.Response.text ("Missing_parameter " ^ s)
  | Error `Invalid_display s -> Morph.Response.text ("Invalid_display " ^ s)
  | Error `Invalid_prompt s -> Morph.Response.text ("Invalid_prompt " ^ s))
  |> Lwt.return
