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

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo "ibmcloud cli not found" >&2
  echo "bin_dir: ${BIN_DIR}" >&2
  ls -l "${BIN_DIR}" >&2
  exit 1
fi

SKIP=$(echo "${INPUT}" | jq -r ".skip")
TMP_DIR=$(echo "${INPUT}" | jq -r ".tmp_dir")
TOKEN=$(echo "${INPUT}" | jq -r ".token")
USERNAME=$(echo "${INPUT}" | jq -r ".username")
PASSWORD=$(echo "${INPUT}" | jq -r ".password")
SERVER=$(echo "${INPUT}" | jq -r '.serverUrl')
KUBECONFIG=$(echo "${INPUT}" | jq -r '.kube_config')

if [[ "${SKIP}" == "true" ]] || [[ -n "${TOKEN}" ]] || [[ ! "${SERVER}" =~ cloud.ibm.com ]]; then
  echo "{\"token\": \"${TOKEN}\", \"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"serverUrl\": \"${SERVER}\", \"skip\": \"${SKIP}\", \"kube_config\": \"${KUBECONFIG}\"}"
  exit 0
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

REGION=$(echo "${SERVER}" | sed -E "s~https://[^.]+.(private[.])?([^.]+)[.].*~\2~g")

ibmcloud login -r "${REGION}" --apikey "${PASSWORD}" 1> /dev/null || exit 1
ibmcloud ks cluster ls | grep -v "Name" | grep -vE "^OK" | sed -E "s/^([^ ]+).*/\1/g" | while read cluster_name; do
  cluster_id=$(ibmcloud ks cluster get -c "${cluster_name}" --output json | \
    jq --arg SERVER "${SERVER}" -r 'select(.serviceEndpoints.publicServiceEndpointURL == $SERVER or .serviceEndpoints.privateServiceEndpointURL == $SERVER) | .id // empty')

  if [[ -n "${cluster_id}" ]]; then
    echo -n "${cluster_id}" > ${TMP_DIR}/.cluster_id
    break
  fi
done

if [[ -f ${TMP_DIR}/.cluster_id ]]; then
  CLUSTER_ID=$(cat ${TMP_DIR}/.cluster_id)
fi

if [[ -z "${CLUSTER_ID}" ]]; then
  echo "{\"token\": \"${TOKEN}\", \"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"serverUrl\": \"${SERVER}\", \"skip\": \"${SKIP}\", \"kube_config\": \"${KUBECONFIG}\"}"
  exit 0
fi

export KUBECONFIG
if ! ibmcloud oc cluster config -c "${CLUSTER_ID}" --admin 1> /dev/null 2> /dev/null; then
  echo "Cluster id: ${CLUSTER_ID}" >&2
  ibmcloud oc cluster config -c "${CLUSTER_ID}" --admin >&2
  ibmcloud --version >&2
  echo "{\"token\": \"${TOKEN}\", \"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"serverUrl\": \"${SERVER}\", \"skip\": \"${SKIP}\", \"kube_config\": \"${KUBECONFIG}\"}"
  exit 1
else
  SKIP="true"
  echo "{\"token\": \"${TOKEN}\", \"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"serverUrl\": \"${SERVER}\", \"skip\": \"${SKIP}\", \"kube_config\": \"${KUBECONFIG}\"}"
  exit 0
fi
