let routes =
  Routes.(
    one_of
      [
        nil @--> LandingPage.make;
        s "auth" /? nil @--> AuthPage.make;
        s "auth" / s "cb" /? nil @--> AuthCallback.make;
      ])

let handler (req: Morph.Request.t): Morph.Response.t Lwt.t =
  match Routes.match' ~target:req.request.message.target routes with
  | None -> Morph.Response.not_found () |> Lwt.return
  | Some h -> h req
