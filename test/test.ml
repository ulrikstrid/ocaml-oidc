let () =
  let path = Sys.getenv_opt "REPORT_PATH" in
  let report = Junit.make [ OidcParameters.suite; Jwt.suite; Jwks.suite ] in
  match path with Some path -> Junit.to_file report path | None -> ()
