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

SKIP=$(echo "${INPUT}" | jq -r '.skip')
SERVER=$(echo "${INPUT}" | jq -r '.serverUrl')
USERNAME=$(echo "${INPUT}" | jq -r '.username')
PASSWORD=$(echo "${INPUT}" | jq -r '.password')
TOKEN=$(echo "${INPUT}" | jq -r '.token')
KUBE_CONFIG=$(echo "${INPUT}" | jq -r '.kube_config')
TMP_DIR=$(echo "${INPUT}" | jq -r '.tmp_dir')
CA_CERT=$(echo "${INPUT}" | jq -r '.ca_cert | @base64d')
USER_CERT=$(echo "${INPUT}" | jq -r '.user_cert | @base64d')
USER_KEY=$(echo "${INPUT}" | jq -r '.user_key | @base64d')

if [[ "${SKIP}" == "true" ]]; then
  echo "{\"token\": \"${TOKEN}\", \"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"serverUrl\": \"${SERVER}\", \"skip\": \"${SKIP}\", \"kube_config\": \"${KUBE_CONFIG}\"}"
  exit 0
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR="${PWD}/.tmp/cluster"
fi
mkdir -p "${TMP_DIR}"

if [[ -z "${KUBE_CONFIG}" ]]; then
  KUBE_CONFIG="${TMP_DIR}/.kube/config"
fi

if [[ -z "${KUBE_CONFIG}" ]] && [[ -z "${USERNAME}" ]] && [[ -z "${PASSWORD}" ]] && [[ -z "${TOKEN}" ]] && [[ -z "${USER_CERT}" ]] && [[ -z "${USER_KEY}" ]]; then
  echo '{"message": "A kube config file, username and password, token or user certificate must be provided to connect to a cluster"}' >&2
  exit 1
fi

KUBE_DIR=$(dirname "${KUBE_CONFIG}")
mkdir -p "${KUBE_DIR}"
touch "${KUBE_CONFIG}"

CERTIFICATE=""
CERT_FILE=""
if [[ -n "${CA_CERT}" ]]; then
  CERT_FILE="${TMP_DIR}/ca.crt"
  echo "${CA_CERT}" > "${CERT_FILE}"
  CERTIFICATE="--certificate-authority=${CERT_FILE}"
fi

USER_CERTIFICATE=""
USER_CERT_FILE=""
if [[ -n "${USER_CERT}" ]]; then
  USER_CERT_FILE="${TMP_DIR}/client.crt"
  echo "${USER_CERT}" > "${USER_CERT_FILE}"
  USER_CERTIFICATE="--client-certificate=${USER_CERT_FILE}"
fi

KEY=""
KEY_FILE=""
if [[ -n "${USER_KEY}" ]]; then
  KEY_FILE="${TMP_DIR}/client.key"
  echo "${USER_KEY}" > "${KEY_FILE}"
  KEY="--client-key=${KEY_FILE}"
fi

if [[ -n "${TOKEN}" ]]; then
  AUTH_TYPE="token"
  if ! oc login --kubeconfig="${KUBE_CONFIG}" --server="${SERVER}" --insecure-skip-tls-verify=true --token="${TOKEN}" ${CERTIFICATE} 1> /dev/null; then
    echo "Error logging in to ${SERVER} with kubeconfig=${KUBE_CONFIG} and auth=${AUTH_TYPE}" >&2
    oc version >&2
    exit 1
  else
    echo "{\"status\": \"success\", \"message\": \"success\", \"kube_config\": \"${KUBE_CONFIG}\", \"serverUrl\":\"${SERVER}\", \"username\":\"${USERNAME}\", \"password\":\"${PASSWORD}\", \"token\":\"${TOKEN}\"}"
    exit 0
  fi
elif [[ -n "${PASSWORD}" ]]; then
  AUTH_TYPE="username(${USERNAME})"
  if ! oc login --kubeconfig="${KUBE_CONFIG}" --insecure-skip-tls-verify=true --username="${USERNAME}" --password="${PASSWORD}" ${CERTIFICATE} "${SERVER}" 1> /dev/null; then
    echo "Error logging in to ${SERVER} with kubeconfig=${KUBE_CONFIG}, auth=${AUTH_TYPE}, and cert_file=${CERT_FILE}" >&2
    cat "${CERT_FILE}" | wc -c | xargs -I{} echo "cert size: {}" >&2
    oc login --kubeconfig="${KUBE_CONFIG}" --insecure-skip-tls-verify=true --username="${USERNAME}" --password="${PASSWORD}" ${CERTIFICATE} "${SERVER}" --loglevel=10 >&2
    exit 1
  else
    echo "{\"status\": \"success\", \"message\": \"success\", \"kube_config\": \"${KUBE_CONFIG}\", \"serverUrl\":\"${SERVER}\", \"username\":\"${USERNAME}\", \"password\":\"${PASSWORD}\", \"token\":\"${TOKEN}\"}"
    exit 0
  fi
else
  AUTH_TYPE="certificate"
  if [[ -z ${SERVER} ]] || [[ -z ${CERTIFICATE} ]] || [[ -z ${USERNAME} ]] || [[ -z ${USER_CERTIFICATE} ]] || [[ -z ${KEY} ]]; then
    echo "Provide Server, username, server ca certificate and user certificate and key to log in using user certificates" >&2
    exit 1
  fi
  export KUBECONFIG=${KUBE_CONFIG} 
  oc config set-cluster cluster --server="${SERVER}" --embed-certs=true ${CERTIFICATE} 1> /dev/null
  oc config set-credentials ${USERNAME} --embed-certs=true ${USER_CERTIFICATE} ${KEY} 1> /dev/null
  oc config set-context cluster --user=${USERNAME} --namespace=default --cluster=cluster 1> /dev/null
  oc config set current-context cluster 1> /dev/null
  echo "{\"status\": \"success\", \"message\": \"success\", \"kube_config\": \"${KUBE_CONFIG}\", \"serverUrl\":\"${SERVER}\", \"username\":\"${USERNAME}\", \"password\":\"${PASSWORD}\", \"token\":\"${TOKEN}\"}"
  exit 0
fi
