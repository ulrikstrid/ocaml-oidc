{ pkgs, stdenv, lib, nix-filter, ocamlPackages, static ? false, doCheck }:

with ocamlPackages;

rec {
  oidc = buildDunePackage {
    pname = "oidc";
    version = "0.0.1-dev";

    src = with nix-filter.lib; filter {
      root = ./..;
      include = [
        "oidc"
        "oidc.opam"
        "dune-project"
      ];
    };

    useDune2 = true;

    propagatedBuildInputs = [
      uri
      jose
      yojson
      logs
      base64
    ];

    inherit doCheck;

    meta = {
      description = "Base functions and types to work with OpenID Connect.";
      license = lib.licenses.bsd3;
    };
  };

  oidc-client = buildDunePackage {
    pname = "oidc-client";
    version = "1.0.0-dev";

    src = with nix-filter.lib; filter {
      root = ./..;
      include = [
        "oidc-client"
        "oidc-client.opam"
        "dune-project"
      ];
    };

    useDune2 = true;

    propagatedBuildInputs = [
      oidc
      jose
      piaf
      uri
      yojson
      logs

      junit
      junit_alcotest
      alcotest
      bisect_ppx
    ];

    inherit doCheck;

    meta = {
      description = "OpenID Connect Relaying Party implementation built ontop of Piaf.";
      license = lib.licenses.bsd3;
    };
  };

  executables = buildDunePackage {
    pname = "executables";
    version = "dev";

    src = with nix-filter.lib; filter {
      root = ./..;
      include = [
        "executable"
        "morph-oidc-client.opam"
        "dune-project"
      ];
    };

    useDune2 = true;

    propagatedBuildInputs = [
      archi
      archi-lwt
      fmt
      lwt
      routes
      uuidm
      oidc
      oauth
      jose
      piaf
      uri
      yojson
      logs
      pkgs.gmp
      dream
      cohttp
      cohttp-lwt-unix
    ];
  };
}
