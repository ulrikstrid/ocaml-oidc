module OidcClient = {
  open Library;
  open Lwt_result.Syntax;

  let start = () => {
    let provider_uri =
      Uri.of_string("https://" ++ Sys.getenv("PROVIDER_HOST"));
    let redirect_uri = Uri.of_string(Sys.getenv("OIDC_REDIRECT_URI"));

    let* oidc_client =
      OidcClient.make(~redirect_uri, provider_uri)
      |> Lwt_result.map_err(Piaf.Error.to_string);

    let registration_uri =
      Uri.with_path(
        provider_uri,
        "/morph_auth_local/rp-response_type-code/registration",
      );

    let+ registration_response =
      OidcClient.RegisterClient.req(~registration_uri);

    Context.make(
      ~oidc_client,
      ~client_id=registration_response.client_id,
      ~secret=registration_response.client_secret,
      (),
    );
  };

  let stop = _ => {
    Logs.info(m => m("Stopped OIDC Client")) |> Lwt.return;
  };

  let component = Archi_lwt.Component.make(~start, ~stop);
};

module WebServer = {
  open Library;
  let server =
    Morph.Server.make(~port=4040, ~address=Unix.inet_addr_loopback, ());

  let start = ((), context) => {
    Logs.info(m => m("Starting server"));
    let handler =
      Morph.Session.middleware(Context.middleware(~context, Router.handler));

    server.start(handler) |> Lwt_result.ok;
  };

  let stop = _server => {
    Logs.info(m => m("Stopped Server")) |> Lwt.return;
  };

  let component =
    Archi_lwt.Component.using(
      ~start,
      ~stop,
      ~dependencies=[OidcClient.component],
    );
};

let system =
  Archi_lwt.System.make([
    ("oidc_client", OidcClient.component),
    ("web_server", WebServer.component),
  ]);

open Lwt.Infix;

let main = () => {
  Fmt_tty.setup_std_outputs();
  Logs.set_level(~all=true, Some(Logs.Debug));
  Logs.set_reporter(Logs_fmt.reporter());
  let () = Mirage_crypto_rng_unix.initialize();

  Archi_lwt.System.start((), system)
  >|= (
    fun
    | Ok(system) => {
        Logs.info(m => m("Starting"));

        Sys.(
          set_signal(
            sigint,
            Signal_handle(
              _ => {
                Logs.err(m => m("SIGNINT received, tearing down.@."));
                Archi_lwt.System.stop(system) |> ignore;
              },
            ),
          )
        );
      }
    | Error(error) => {
        Logs.err(m => m("ERROR: %s@.", error));
        exit(1);
      }
  );
};

let () = Lwt_main.run(main());
