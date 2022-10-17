#!/usr/bin/env bash

BIN_DIR=$(cat .bin_dir)
export KUBECONFIG=$(cat .kubeconfig)

echo "Kube config: ${KUBECONFIG}"

export PATH="${BIN_DIR}:${PATH}"

echo "oc api-resources"
if [[ $(oc api-resources -o name | wc -l) -eq 0 ]]; then
  echo "Unable to retrieve api resources using oc cli" >&2
  exit 1
fi

echo "kubectl api-resources"
if [[ $(kubectl api-resources -o name | wc -l) -eq 0 ]]; then
  echo "Unable to retrieve api resources using kubectl cli" >&2
  exit 1
fi

cat .outputs
