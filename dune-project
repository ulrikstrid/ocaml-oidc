(lang dune 2.5)

(name morph_oidc_client)

(license BSD3)

(source
 (github ulrikstrid/ocaml-oidc))

(homepage https://ulrikstrid.github.io/ocaml-oidc)

(documentation https://ulrikstrid.github.io/ocaml-oidc)

(authors "Ulrik Strid")

(maintainers "ulrik.strid@outlook.com")

(generate_opam_files true)

(package
 (version 0.1.0)
 (name oidc)
 (synopsis "Base package for working with OIDC")
 (description "Base functions and types to work with OpenID Connect.")
 (depends
  (ocaml
   (>= 4.08.0))
  (dune
   (>= 1.11))
  (jose
   (>= 0.5.1))
  uri
  uunf
  yojson
  logs))

(package
 (version 0.1.0)
 (name oidc-client)
 (synopsis "OIDC client based on Piaf")
 (description
   "OpenID Connect Relaying Party implementation built ontop of Piaf.")
 (depends
  (ocaml
   (>= 4.08.0))
  (dune
   (>= 1.11))
  (jose
   (>= 0.5.1))
  oidc
  uri
  yojson
  logs
  piaf
  astring))

(package
 (version 0.1.0)
 (name morph-oidc-client))
