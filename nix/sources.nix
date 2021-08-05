{ ocamlVersion ? "4_11" }:
let
  overlays =
    builtins.fetchTarball
      https://github.com/anmonteiro/nix-overlays/archive/33e48758d44f37d0331b9f4d51b9b35911ca792f.tar.gz;

in
import "${overlays}/sources.nix" {
  overlays = [
    (import overlays)
    (self: super: {
      ocamlPackages = super.ocaml-ng."ocamlPackages_${ocamlVersion}";

      pkgsCross.musl64.pkgsStatic = super.pkgsCross.musl64.pkgsStatic.appendOverlays [
        (self: super: {
          ocamlPackages = super.ocaml-ng."ocamlPackages_${ocamlVersion}";
        })
      ];
    })
  ];
}
