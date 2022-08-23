{ nix-filter }:

final: prev:

{
  ocaml-ng = builtins.mapAttrs
    (_: ocamlVersion:
      ocamlVersion.overrideScope' (oself: osuper:
        (prev.callPackage ./generic.nix { inherit nix-filter; doCheck = true; }))
    )
    prev.ocaml-ng;
}
