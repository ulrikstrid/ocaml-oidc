# ocaml-oidc

OpenID connect implementation in OCaml.

## Folder structure

```
ocaml-oidc
│
├─executable/  Entrypoint for a webserver/OIDC client
│
├─library/     Implementation for the webserver
│
├─oidc/        Core OIDC implementation
│
├─oidc-client/ OIDC Client implementation
│
├─test/        tests
│
```

## Developing:

```
npm install -g esy redemon reenv
git clone <this-repo>
esy install
esy build
```

## Running Binary:

After building the project, you can run the main binary that is produced. This will start a webserver with a OIDC client configured for certification.

```
esy start
```

## Running Tests:

```
# Runs the "test" command in `package.json`.
esy test
```
