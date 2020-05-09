open Lwt_result.Infix;
open Library;

Fmt_tty.setup_std_outputs();
Logs.set_level(~all=true, Some(Logs.Debug));
Logs.set_reporter(Logs_fmt.reporter());

let http_server =
  Morph.Server.make(~address=Unix.inet_addr_loopback, ());
let provider_uri = Uri.of_string(Sys.getenv("PROVIDER_HOST"));

GetDiscovery.req(~provider_uri, ())
>>= (
  body => {
    let discovery = Oidc.Discover.of_string(body);

    RegisterClient.req()
    >>= (
      client => {
        Logs.info(m => m("%s", client));
        let registration_response =
          Oidc.DynamicRegistration.response_of_string(client);

        switch (registration_response) {
        | Ok(registration_response) =>
          let context =
            Context.make(
              ~discovery,
              ~client_id=registration_response.client_id,
              ~redirect_uri="http://localhost:8080/auth/cb",
              ~secret=registration_response.client_secret,
              (),
            );

          if (Sys.unix) {
            Sys.(set_signal(sigpipe, Signal_handle(_ => ())));
          };

          let handler = Context.middleware(~context, Router.handler);

          http_server.start(handler) |> Lwt_result.ok;
        | Error(e) => failwith(e)
        };
      }
    );
  }
)
|> Lwt_main.run
|> (
  fun
  | Ok () => print_endline("started")
  | Error(msg) => Logs.err(m => m("%s", msg))
);
