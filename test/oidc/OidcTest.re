open TestFramework;

describe("OIDC - Parameters", ({test}) => {
  let client: Oidc.Client.t = {
    id: "s6BhdRkqt3",
    redirect_uri: "https://client.example.org/cb",
    secret: Some("secret"),
  };
  let clients = [client];

  let base_url = "http://localhost:3000/authorize";
  let valid_query = "?response_type=code&client_id=s6BhdRkqt3&redirect_uri=https://client.example.org/cb&scope=openid%20profile&state=af0ifjsldkj&nonce=n-0S6_WzA2Mj";

  test("parseQuery", ({expect}) => {
    switch (
      Oidc.Parameters.parse_query(
        ~clients,
        Uri.of_string(base_url ++ valid_query),
      )
    ) {
    | Valid(validParameters) =>
      expect.string(validParameters.client.id).toEqual("s6BhdRkqt3");
      expect.string(validParameters.redirect_uri).toEqual(
        "https://client.example.org/cb",
      );
      expect.string(validParameters.nonce).toEqual("n-0S6_WzA2Mj");
    | _ => ()
    }
  });

  test("to_query", ({expect}) => {
    let parameters =
      Oidc.Parameters.{
        response_type: ["code"],
        client,
        redirect_uri: "https://client.example.org/cb",
        scope: ["openid", "profile"],
        state: Some("af0ifjsldkj"),
        nonce: "n-0S6_WzA2Mj",
        claims: None,
        max_age: None,
        display: None,
        prompt: None,
      };

    expect.equal(valid_query, Oidc.Parameters.to_query(parameters));
  });
});

describe("OIDC - Claims", u =>
  Oidc.Claims.(
    u.test("from_string", ({expect}) => {
      let claims_string = {|{
      "id_token" : {
          "email"          : null,
          "email_verified" : { "essential" : true }
      },
      "userinfo": {
          "email"          : null,
          "email_verified" : { "essential" : true },
          "name"           : null
      }
   }|};

      let claims = from_string(claims_string);

      expect.list(claims.id_token).toContainEqual(NonEssential("email"));
      expect.list(claims.id_token).toContainEqual(
        Essential("email_verified"),
      );
      expect.list(claims.userinfo).toContainEqual(NonEssential("email"));
      expect.list(claims.userinfo).toContainEqual(
        Essential("email_verified"),
      );
    })
  )
);
