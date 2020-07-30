#!/bin/bash
set -euo pipefail

kubectl --context microk8s -n default delete pods -l app=morph-oidc-client

printf "Waiting 2 seconds before tailing pod logs "
sleep 1
printf "."
sleep 1
printf ".\n"

kubectl --context microk8s -n default logs --follow -l app=morph-oidc-client
