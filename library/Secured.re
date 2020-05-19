let markup =
    (~id_token: string, ~header: string, ~payload: string, ~signature: string) =>
  Tyxml.(
    <Layout title="Secured">
      <h3> "Header" </h3>
      <pre> <code className="language-JSON"> {Html.txt(header)} </code> </pre>
      <h3> "Payload" </h3>
      <pre>
        <code className="language-JSON"> {Html.txt(payload)} </code>
      </pre>
      <h3> "Signature" </h3>
      <pre>
        <code className="language-JSON"> {Html.txt(signature)} </code>
      </pre>
      <h3> "id_token" </h3>
      <pre> <code> {Html.txt(id_token)} </code> </pre>
    </Layout>
  );

let handle: Morph.Server.handler =
  req => {
    open Lwt.Syntax;

    let+ id_token_result = Morph.Session.get(req, ~key="id_token");

    switch (id_token_result) {
    | Ok(id_token) =>
      let jwt = Jose.Jwt.of_string(id_token) |> Result.get_ok;
      let header =
        Yojson.Safe.pretty_to_string(jwt.header |> Jose.Header.to_json);
      let payload = Yojson.Safe.pretty_to_string(jwt.payload);

      TyxmlRender.respond_html(
        markup(~id_token, ~header, ~payload, ~signature=jwt.signature),
      );
    | Error(_) => Morph.Response.redirect("/")
    };
  };
