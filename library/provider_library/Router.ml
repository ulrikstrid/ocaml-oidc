let well_known_openid : (Morph.Server.handler, 'a) Routes.target =
  Routes.(s ".well-known" / s "openid-configuration" /? nil)

let auth : (Morph.Server.handler, 'a) Routes.target = Routes.(s "auth" /? nil)

let token : (Morph.Server.handler, 'a) Routes.target = Routes.(s "token" /? nil)

let get_routes clients =
  Routes.
    [
      well_known_openid @--> WellKnown.handler;
      auth @--> AuthRoute.handler clients;
      token @--> TokenRoute.handler;
      InteractionRoute.get_route;
    ]

let post_routes =
  [ InteractionRoute.post_route ]

let handler clients =
  Morph.Router.make ~get:(get_routes clients) ~post:post_routes
    ~not_found_handler:(fun _ -> Morph.Response.not_found () |> Lwt.return)
    ()
