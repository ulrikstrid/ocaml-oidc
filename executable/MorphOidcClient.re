module OidcClient = {
  open Lwt_result.Syntax;

  let start = () => {
    /*let provider_uri =
      Uri.of_string("https://" ++ Sys.getenv("PROVIDER_HOST"));*/
    let redirect_uri = Uri.of_string(Sys.getenv("OIDC_REDIRECT_URI"));
    /*
     let client_meta =
       Oidc.Client.make_meta(
         ~redirect_uris=[Uri.to_string(redirect_uri)],
         ~contacts=["ulrik.strid@outlook.com"],
         ~response_types=["code"],
         ~grant_types=["authorization_code"],
         ~token_endpoint_auth_method="client_secret_post",
         (),
       );

      let+ oidc_client =
        OidcClient.make(
          ~redirect_uri,
          ~provider_uri,
          ~client=OidcClient.Register(client_meta),
        )
        |> Lwt_result.map_err(Piaf.Error.to_string);
      */

    let kv:
      module OidcClient.KeyValue.KV with
        type value = string and type store = Hashtbl.t(string, string) =
      (module OidcClient.KeyValue.MemoryKV);

    let+ oidc_client =
      OidcClient.Microsoft.make(
        ~kv,
        ~store=Hashtbl.create(128),
        ~app_id="2824b599-24f1-4595-b63b-0cab4bb26c24",
        ~tenant_id="5c26a08a-b3ca-475d-abfc-a96df0a5593e",
        ~redirect_uri,
        ~secret=Sys.getenv_opt("OIDC_SECRET"),
      )
      |> Lwt_result.map_err(Piaf.Error.to_string);

    oidc_client;
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
