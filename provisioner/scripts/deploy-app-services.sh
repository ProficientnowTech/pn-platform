#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INVENTORY="$ROOT_DIR/inventory/production/hosts.yml"
PLAYBOOK="$ROOT_DIR/playbooks/app_services_deploy.yml"
LIMIT=""
SOURCE_REPO_PATH="/home/doxbox/pnow-ats-v2"

usage() {
  cat <<'EOF'
Usage:
  deploy-app-services.sh [--host <inventory-host>] [--inventory <path>] [--repo <path>] [--teardown] [--all] [service selectors...] [-- <ansible args>]

Service selector styles:
  --kafka-broker-1
  --redis
  --pi-scrape
  audit-api-service

Examples:
  deploy-app-services.sh --host app-server-01 --pi-scrape
  deploy-app-services.sh --host app-server-01 --pi-scrape kafka-broker-1 redis
  deploy-app-services.sh --host app-server-01 --teardown --pi-scrape

Notes:
  - --pi-scrape targets api+worker+temporal-worker.
  - --pi-scrape-api targets only api.
  - Unknown selectors fail fast with a clear error.
EOF
}

declare -a SELECTORS=()
declare -a ANSIBLE_PASSTHROUGH=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      ANSIBLE_PASSTHROUGH+=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --host|--limit)
      LIMIT="$2"
      shift 2
      ;;
    --inventory)
      INVENTORY="$2"
      shift 2
      ;;
    --repo)
      SOURCE_REPO_PATH="$2"
      shift 2
      ;;
    --teardown)
      PLAYBOOK="$ROOT_DIR/playbooks/app_services_teardown.yml"
      shift
      ;;
    --all)
      SELECTORS=()
      shift
      ;;
    --*)
      SELECTORS+=("${1#--}")
      shift
      ;;
    *)
      SELECTORS+=("$1")
      shift
      ;;
  esac
done

declare -a COMPOSE_FILES=(
  "docker/docker-compose.yml"
  "docker/pi-scrape.docker-compose.yml"
  "apps/backend/audit-service/docker-compose.yml"
  "apps/backend/tasks-reminders/docker-compose.yml"
  "apps/backend/pi-boolgen/docker-compose.yml"
  "apps/backend/pi-mailsum/docker-compose.yml"
)

declare -A SERVICE_TO_COMPOSE=()
for compose in "${COMPOSE_FILES[@]}"; do
  [[ -f "$SOURCE_REPO_PATH/$compose" ]] || continue
  while IFS= read -r svc; do
    [[ -z "$svc" ]] && continue
    if [[ -z "${SERVICE_TO_COMPOSE[$svc]:-}" ]]; then
      SERVICE_TO_COMPOSE["$svc"]="$compose"
    fi
  done < <(awk '
    BEGIN { in_services=0 }
    /^services:/ { in_services=1; next }
    in_services && /^[^[:space:]]/ { exit }
    in_services && /^  [a-zA-Z0-9_.-]+:/ {
      gsub(":", "", $1);
      print $1
    }' "$SOURCE_REPO_PATH/$compose")
done

declare -A ALIASES=(
  ["pi-scrape"]="docker/pi-scrape.docker-compose.yml:api,worker,temporal-worker"
  ["pi-scrape-api"]="docker/pi-scrape.docker-compose.yml:api"
  ["audit-api"]="apps/backend/audit-service/docker-compose.yml:audit-api-service"
)

declare -A SELECTED_COMPOSES=()
declare -A SELECTED_SERVICES_BY_COMPOSE=()

add_service() {
  local compose="$1"
  local service="$2"
  SELECTED_COMPOSES["$compose"]=1

  local existing="${SELECTED_SERVICES_BY_COMPOSE[$compose]:-}"
  if [[ -z "$existing" ]]; then
    SELECTED_SERVICES_BY_COMPOSE["$compose"]="$service"
    return
  fi
  if [[ ",$existing," != *",$service,"* ]]; then
    SELECTED_SERVICES_BY_COMPOSE["$compose"]+=",${service}"
  fi
}

if [[ "${#SELECTORS[@]}" -gt 0 ]]; then
  for selector in "${SELECTORS[@]}"; do
    if [[ -n "${ALIASES[$selector]:-}" ]]; then
      compose="${ALIASES[$selector]%%:*}"
      csv="${ALIASES[$selector]#*:}"
      IFS=',' read -r -a svcs <<< "$csv"
      for svc in "${svcs[@]}"; do
        add_service "$compose" "$svc"
      done
      continue
    fi

    if [[ -n "${SERVICE_TO_COMPOSE[$selector]:-}" ]]; then
      add_service "${SERVICE_TO_COMPOSE[$selector]}" "$selector"
      continue
    fi

    echo "Unknown selector: $selector" >&2
    echo "Tip: use --help for supported selector styles." >&2
    exit 2
  done
fi

CMD=(ansible-playbook -i "$INVENTORY" "$PLAYBOOK")
if [[ -n "$LIMIT" ]]; then
  CMD+=(--limit "$LIMIT")
fi
if [[ "${#ANSIBLE_PASSTHROUGH[@]}" -gt 0 ]]; then
  CMD+=("${ANSIBLE_PASSTHROUGH[@]}")
fi

if [[ "${#SELECTORS[@]}" -gt 0 ]]; then
  tmpfile="$(mktemp)"
  for compose in "${!SELECTED_COMPOSES[@]}"; do
    echo "${compose}|${SELECTED_SERVICES_BY_COMPOSE[$compose]}" >> "$tmpfile"
  done

  EXTRA_JSON="$(python3 - "$tmpfile" <<'PY'
import json
import sys
from pathlib import Path

rows = []
for line in Path(sys.argv[1]).read_text().splitlines():
    if not line.strip():
        continue
    compose, csv = line.split("|", 1)
    services = [s for s in csv.split(",") if s]
    rows.append((compose, services))

rows.sort(key=lambda x: x[0])
payload = {
    "app_deploy_target_compose_files": [c for c, _ in rows],
    "app_deploy_services_by_compose": {c: s for c, s in rows},
}
print(json.dumps(payload))
PY
)"
  rm -f "$tmpfile"
  CMD+=(-e "$EXTRA_JSON")
fi

echo "Running: ${CMD[*]}"
exec "${CMD[@]}"
