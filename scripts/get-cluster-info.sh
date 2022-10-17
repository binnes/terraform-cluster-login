#!/usr/bin/env bash

INPUT=$(tee)
BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]*)".*/\1/g')

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  echo "bin_dir: ${BIN_DIR}" >&2
  ls -l "${BIN_DIR}" >&2
  exit 1
fi

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  echo "bin_dir: ${BIN_DIR}" >&2
  ls -l "${BIN_DIR}" >&2
  exit 1
fi

export KUBECONFIG=$(echo "${INPUT}" | jq -r '.kube_config')
DEFAULT_INGRESS=$(echo "${INPUT}" | jq -r '.default_ingress // empty')

OCP_ID=$(oc get clusterversion -o json | jq -r '.items[].spec.clusterID')

NODE_NAME=$(oc get nodes -o json | jq -r '.items[] | .metadata.name' | head -1)
NODE_INFO=$(oc get nodes "${NODE_NAME}" -o json)

IBM_REGION=$(echo "${NODE_INFO}" | jq -r '.metadata.labels["ibm-cloud.kubernetes.io/region"] // empty')
if [[ -n "${IBM_REGION}" ]]; then
  PROVIDER_ID=$(echo "${NODE_INFO}" | jq -r '.spec.providerID')

  CLUSTER_ID=$(echo "${PROVIDER_ID}" | sed -E 's~ibm://[^/]+/[^/]*/[^/]*/([^/]+)/.*~\1~g')
else
  CLUSTER_ID="${OCP_ID}"
fi

INGRESS=$(oc get ingresses.config/cluster -o json | jq -r --arg DEFAULT "${DEFAULT_INGRESS}" '.spec.domain // $DEFAULT')
VERSION=$(oc version -o json | jq -r '.openshiftVersion // empty')
TLS_SECRET=$(oc get ingresscontroller.operator -n openshift-ingress-operator default -o json | jq -r '.spec.defaultCertificate.name // empty')
PLATFORM_TYPE=$(if oc get clusterversion > /dev/null 2>&1; then echo "openshift" ; else  echo "kubernetes" ; fi)
PLATFORM_CODE=$(if [[ $PLATFORM_TYPE = "openshift" ]] ; then echo "ocp4" ; else echo "kubernetes" ; fi)
jq -n \
  --arg INGRESS "${INGRESS}" \
  --arg VERSION "${VERSION}" \
  --arg TLS_SECRET "${TLS_SECRET}" \
  --arg CLUSTER_ID "${CLUSTER_ID}" \
  --arg OCP_ID "${OCP_ID}" \
  --arg PLATFORM_TYPE "${PLATFORM_TYPE}" \
  --arg PLATFORM_CODE "${PLATFORM_CODE}" \
  '{"ingress_subdomain": $INGRESS, "cluster_version": $VERSION, "tls_secret": $TLS_SECRET, "cluster_id": $CLUSTER_ID, "ocp_id": $OCP_ID, "platform_type": $PLATFORM_TYPE, "platform_code": $PLATFORM_CODE }'
