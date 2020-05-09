let make = _request => {
  open Tyxml;

  let body =
    <html>
      <head>
        <title> "Landing page" </title>
        <link
          href="https://unpkg.com/tailwindcss@^1.0/dist/tailwind.min.css"
          rel="stylesheet"
        />
      </head>
      <body>
        <div className="container mx-auto font-sans">
          <h1 className="font-sans text-xl text-gray-800 text-center">
            "Landing page"
          </h1>
          <a href="/auth"> "Login" </a>
        </div>
      </body>
    </html>
    |> Format.asprintf("%a", Html.pp(~indent=false, ()));

  Morph.Response.html(body) |> Lwt.return;
};
