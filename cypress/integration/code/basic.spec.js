describe("Response Type and Response Mode", () => {
  it("rp-response_type-code", () => {
    cy.visit("/");

    cy.log("Make an authentication request using the Authorization Code Flow.");

    cy.contains("rp-response_type-code").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-response_type-code"
    );
  });
});

describe("scope Request Parameter", () => {
  it("rp-scope-userinfo-claims", () => {
    cy.visit("/");

    cy.log("Request claims using scope values.");

    cy.contains("rp-scope-userinfo-claims").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-scope-userinfo-claims"
    );
  });
});

describe("nonce Request Parameter", () => {
  it("rp-nonce-invalid", () => {
    cy.visit("/");

    cy.contains("rp-nonce-invalid").click();

    cy.contains("Invalid nonce value");
  });
});

describe("Client Authentication", () => {
  it("rp-token_endpoint-client_secret_basic", () => {
    cy.visit("/");

    cy.contains("rp-token_endpoint-client_secret_basic").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-token_endpoint-client_secret_basic"
    );
  });
});

describe("ID Token", () => {
  it("rp-id_token-kid-absent-single-jwks", () => {
    cy.visit("/");

    cy.contains("rp-id_token-kid-absent-single-jwks").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-id_token-kid-absent-single-jwks"
    );
  });

  it("rp-id_token-iat", () => {
    cy.visit("/");

    cy.contains("rp-id_token-iat").click();

    cy.contains("Missing iat");
  });

  it("rp-id_token-aud", () => {
    cy.visit("/");

    cy.contains("rp-id_token-aud").click();

    cy.contains("aud");
  });

  it("rp-id_token-kid-absent-multiple-jwks", () => {
    cy.visit("/");

    cy.contains("rp-id_token-kid-absent-multiple-jwks").click();

    cy.contains("Could not find JWK");
  });

  it("rp-id_token-sig-none", () => {
    cy.visit("/");

    cy.contains("rp-id_token-sig-none").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-id_token-sig-none"
    );
  });

  it("rp-id_token-sig-rs256", () => {
    cy.visit("/");

    cy.contains("rp-id_token-sig-rs256").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-id_token-sig-rs256"
    );
  });

  it("rp-id_token-sub", () => {
    cy.visit("/");

    cy.contains("rp-id_token-sub").click();

    cy.contains("Missing sub");
  });

  it("rp-id_token-bad-sig-rs256", () => {
    cy.visit("/");

    cy.contains("rp-id_token-bad-sig-rs256").click();

    cy.contains("Invalid signature");
  });

  it("rp-id_token-issuer-mismatch", () => {
    cy.visit("/");

    cy.contains("rp-id_token-issuer-mismatch").click();

    cy.contains("Wrong iss value");
  });
});

describe("UserInfo Endpoint", () => {
  it("rp-userinfo-bad-sub-claim", () => {
    cy.visit("/");

    cy.contains("rp-userinfo-bad-sub-claim").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-userinfo-bad-sub-claim"
    );

    cy.contains("sub doesn't match id_token");
  });

  it("rp-userinfo-bearer-header", () => {
    cy.visit("/");

    cy.contains("rp-userinfo-bearer-header").click();

    cy.contains(
      "https://rp.certification.openid.net:8080/morph_auth_local/rp-userinfo-bearer-header"
    );
  });
});
