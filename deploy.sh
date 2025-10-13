#!/usr/bin/env bash

set -euo pipefail

TF_CMD="${TF_CMD:-tofu}"
ANSIBLE_CMD="${ANSIBLE_CMD:-ansible-playbook}"
SLEEP_INTERVAL=15

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT_DIR}/terraform"
ANSIBLE_DIR="${ROOT_DIR}/anycast/base-ansible-template"
PLAYBOOKS=("bgp.yaml" "nginx2.yaml")
SITES=("den" "sea" "pdx")

ensure_tool() {
  local tool="$1"
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'Error: required command "%s" not found in PATH\n' "$tool" >&2
    exit 1
  }
}

log() {
  printf '\n==> %s\n' "$*"
}

sleep_step() {
  sleep "$SLEEP_INTERVAL"
}

run_terraform() {
  ensure_tool "$TF_CMD"
  pushd "$TF_DIR" >/dev/null
  "$TF_CMD" init -input=false >/dev/null
  "$TF_CMD" apply -auto-approve
  popd >/dev/null
}

run_ansible() {
  ensure_tool "$ANSIBLE_CMD"
  pushd "$ANSIBLE_DIR" >/dev/null

  for site in "${SITES[@]}"; do
    local limit="${site}*"
    log "Running playbooks for ${site^^} (limit ${limit})"

    for playbook in "${PLAYBOOKS[@]}"; do
      if [[ ! -f "$playbook" ]]; then
        printf 'Warning: playbook "%s" not found, skipping.\n' "$playbook"
        continue
      fi

      log "Playbook ${playbook}"
      "$ANSIBLE_CMD" -i hosts "$playbook" --limit "$limit" --forks 1
    done

    sleep_step
  done

  popd >/dev/null
}

main() {
  run_terraform

  sleep_step
  echo "Infrastructure Deployed"
  sleep_step
  echo "Deploying Anycast Ingress"
  sleep_step
  echo " - Running Playbooks:"
  sleep_step

  run_ansible
}

main "$@"
