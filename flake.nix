{
  description = "OpenID Connect implementation for OCaml";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  
    flake-utils.url = "github:numtide/flake-utils";

    ocaml-overlay.url = "github:anmonteiro/nix-overlays/ulrikstrid/unvendor-piaf-dream";
    ocaml-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ocaml-overlay, flake-utils }:
    {
        overlay = final: prev: { ocamlPackages = prev.ocaml-ng.ocamlPackages_4_12.overrideScope'
          (builtins.foldl' final.lib.composeExtensions (_: _: { }) [
            (oself: osuper: ( prev.callPackage ./nix/generic.nix { doCheck = true; }))
          ]);
        };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ ocaml-overlay.overlay ]; };
        inherit (pkgs) lib;
        oidcPkgs = pkgs.recurseIntoAttrs (import ./nix { inherit pkgs; doCheck = true; }).native;
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
                ocamlformat_0_20_1
                odoc
                reenv
                # dune-release
                cacert
                curl
                which
                inotify-tools
            ];
            }).overrideAttrs (o: {
            propagatedBuildInputs = filterDrvs o.propagatedBuildInputs;
            buildInputs = filterDrvs o.buildInputs;
            checkInputs = filterDrvs o.checkInputs;
        });
      in
      {
        inherit devShell;
      }
    );
}
