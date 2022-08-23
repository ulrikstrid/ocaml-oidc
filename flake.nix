{
  description = "OpenID Connect implementation for OCaml";

  nixConfig = {
    extra-substituters = "https://anmonteiro.nix-cache.workers.dev";
    extra-trusted-public-keys = "ocaml.nix-cache.com-1:/xI2h2+56rwFfKyyFVbkJSeGqSIYMC/Je+7XXqGKDIY=";
  };

  inputs = {
    nixpkgs.url = "github:nix-ocaml/nix-overlays/0081a01960591e7415986eca055887ca76689799";

    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.inputs.flake-utils.follows = "flake-utils";

    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, nix-filter, flake-utils }:
    {
      overlays.default = import ./nix/overlays.nix { inherit nix-filter; };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";
        inherit (pkgs) lib;
        oidcPkgs = pkgs.recurseIntoAttrs (import ./nix { inherit pkgs nix-filter; doCheck = true; }).native;
        oidcDrvs = lib.filterAttrs (_: value: lib.isDerivation value) oidcPkgs;

        filterDrvs = inputs:
          lib.filter
            (drv:
              # we wanna filter our own packages so we don't build them when entering
              # the shell. They always have `pname`
              !(lib.hasAttr "pname" drv) ||
              drv.pname == null ||
              !(lib.any (name: name == drv.pname || name == drv.name) (lib.attrNames oidcDrvs)))
            inputs;
        devShell = (pkgs.mkShell {
          inputsFrom = lib.attrValues oidcDrvs;
          buildInputs = with pkgs; with ocamlPackages; [
            ocaml-lsp
            ocamlformat
            odoc
            reenv
            # dune-release
            cacert
            curl
            which
          ];
        }).overrideAttrs (o: {
          propagatedBuildInputs = filterDrvs o.propagatedBuildInputs;
          buildInputs = filterDrvs o.buildInputs;
          checkInputs = filterDrvs o.checkInputs;
        });
      in
      {
        inherit devShell;
        packages = {
          oidc = oidcPkgs.oidc;
        };
      }
    );
}
