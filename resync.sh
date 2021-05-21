#!/bin/bash

RESYNC_DRY_RUN="${RESYNC_DRY_RUN:-false}"
RESYNC_INVENTORY_BUCKET_NAME="${RESYNC_INVENTORY_BUCKET_NAME}"
RESYNC_INVENTORY_FILE_PATH="${RESYNC_INVENTORY_FILE_PATH}"
RESYNC_ADD_ARGS="${ADD_ARGS:-"--acl bucket-owner-full-control"}"

VAR_TMP_FOLDER=$(mktemp -d)
TMP_FOLDER=${RESYNC_TMP_FOLDER:-$VAR_TMP_FOLDER}

function tmp_filename() {
  echo "${TMP_FOLDER}/$(echo $1 | sha256sum | cut -d " " -f1)"
}

function get_inventory() {
  aws s3 cp "s3://${RESYNC_INVENTORY_BUCKET_NAME}/${RESYNC_INVENTORY_FILE_PATH}" "${TMP_FOLDER}/inventory.csv.gz"

  gunzip "${TMP_FOLDER}/inventory.csv.gz"
}

function reupload_file() {
  # $1 file path
  # $2 source bucket name
  source="s3://${2}/${1}"
  target="$(tmp_filename "${1}")"

  if [[ "${RESYNC_DRY_RUN}" == "true" ]]; then
    echo aws s3 cp "${source}" "${target}" ${ADD_ARGS} >&2
    echo aws s3 cp "${target}" "${source}" ${ADD_ARGS} >&2
  else
    aws s3 cp "${source}" "${target}" ${ADD_ARGS} || return

    aws s3 cp "${target}" "${source}" ${ADD_ARGS} || exit 1

    # cleanup
    rm "${target}"
  fi
}

function filter_inventory() {
  grep FAILED "${TMP_FOLDER}/inventory.csv" > "${TMP_FOLDER}/inventory_filtered.csv"
}

function main() {
  if [[ "${RESYNC_INVENTORY_BUCKET_NAME}" == "" || "${RESYNC_INVENTORY_FILE_PATH}" == "" ]]; then
    echo "RESYNC_INVENTORY_BUCKET_NAME or RESYNC_INVENTORY_FILE_PATH not set"
    return 1
  fi

  if ! $(aws sts get-caller-identity >/dev/null 2>&1); then
    echo "AWS connection failed"
    return 1
  fi

  #start clean
  rm -Rf "${TMP_FOLDER}/*"
  rm -Rf "${TMP_FOLDER}/.*"

  if ! get_inventory; then
    echo "error getting inventory file"
    return 1
  fi

  filter_inventory

  while read i; do
    bucket=$(echo $i | cut -d ',' -f1 | tr -d '"')
    filepath=$(echo $i | cut -d ',' -f2 | tr -d '"')

    reupload_file "${filepath}" "${bucket}"

    echo "REUPLOADED s3://${bucket}/${filepath}"
  done < "${TMP_FOLDER}/inventory_filtered.csv"
}

main
exit $?
