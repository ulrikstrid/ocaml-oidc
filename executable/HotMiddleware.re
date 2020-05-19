let middleware = (): Morph.Server.middleware => {
  let handler = ref(Library.Router.handler);

  let watcher = Luv.FS_event.init() |> Result.get_ok;

  let load_dir = Sys.getenv("DUNE_BUILD_DIR");

  Luv.FS_event.start(
    ~recursive=true,
    ~watch_entry=true,
    watcher,
    load_dir,
    fun
    | Ok((file, _events)) =>
      if (String.sub(file, String.length(file) - 3, 3) == "cmo") {
        let file_path = load_dir ++ "/" ++ file;
        print_endline(file_path ++ " updated, setting new handler");
        if (!Sys.file_exists(file_path)) {
          Luv.Time.sleep(150);
        };
        try(Dynlink.loadfile(file_path)) {
        | Dynlink.Error(err) =>
          print_endline(
            "ERROR loading plugin: " ++ Dynlink.error_message(err),
          )
        | e =>
          failwith(
            "Unknown error while loading plugin: " ++ Printexc.to_string(e),
          )
        };
        handler := Library.Router.handler;
      }
    | Error(e) =>
      Printf.eprintf("Error starting watcher: %s\n", Luv.Error.strerror(e)),
  );

  ignore(Luv.Loop.run(): bool);

  _next => {
    handler^;
  };
};
