let well_known_openid : (Morph.Server.handler, 'a) Routes.target =
  Routes.(s ".well-known" / s "openid-configuration" /? nil)

let auth : (Morph.Server.handler, 'a) Routes.target = Routes.(s "auth" /? nil)

let token : (Morph.Server.handler, 'a) Routes.target = Routes.(s "token" /? nil)

let interaction : (string -> Morph.Server.handler, 'a) Routes.target =
  Routes.(s "interaction" / str /? nil)

let routes clients =
  Routes.(
    one_of
      [
        well_known_openid @--> WellKnown.handler;
        auth @--> AuthRoute.handler clients;
        token @--> TokenRoute.handler;
        interaction @--> InteractionRoute.handler;
      ])

let handler routes (req : Morph.Request.t) : Morph.Response.t Lwt.t =
  match Routes.match' ~target:req.request.target routes with
  | None -> Morph.Response.not_found () |> Lwt.return
  | Some h -> h req
