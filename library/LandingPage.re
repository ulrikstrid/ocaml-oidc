let make = _request => {
  open Tyxml;

  let body =
    <Layout title="Landing page">
      <main className="my-16 grid grid-cols-3 gap-4">
        <div />
        <Card title="Welcome"> <a href="/auth"> "Go to login" </a> </Card>
        <div />
      </main>
    </Layout>;

  TyxmlRender.respond_html(body) |> Lwt.return;
};
