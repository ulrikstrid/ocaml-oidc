#!/bin/sh

TAG="$1"

if [ -z "$TAG" ]; then
  printf "Usage: ./dune-release.sh <tag-name>\n"
  printf "Please make sure that dune-release is available.\n"
  exit 1
fi

step()
{
  printf "Continue? [Yn] "
  read action
  if [ "$action" = "n" ]; then exit 2; fi
  if [ "$action" = "N" ]; then exit 2; fi
}

dune-release tag "$TAG"
step
dune-release distrib -p oidc -n oidc -t "$TAG" --skip-tests #--skip-lint
step
dune-release publish distrib -p oidc -n oidc -t "$TAG"
step
dune-release opam pkg -p oidc -n oidc -t "$TAG"
step
dune-release opam submit -p oidc -n oidc -t "$TAG"
