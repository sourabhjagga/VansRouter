#!/usr/bin/env bash
# Runs ON THE VPS (via SSH forced command). Triggers a Coolify deployment of
# the vans-router app using the localhost Coolify API, polls until terminal,
# and exits 0 on success / 1 on failure. Coolify API is never exposed publicly.
#
# Required on the VPS:
#   - Coolify API token in $COOLIFY_TOKEN_FILE (default /etc/coolify/api-token)
#   - jq installed
#   - COOLIFY_APP_UUID env or default below
set -euo pipefail

APP_UUID="${COOLIFY_APP_UUID:-obw7oljvlg2siu2mzxpr6rwv}"
TOKEN_FILE="${COOLIFY_TOKEN_FILE:-/etc/coolify/api-token}"
BASE="${COOLIFY_BASE_URL:-http://127.0.0.1:8000}"

if [ ! -r "$TOKEN_FILE" ]; then
  echo "ERROR: Coolify token file not readable: $TOKEN_FILE" >&2
  exit 1
fi
TOKEN="$(cat "$TOKEN_FILE")"

echo "=== Triggering Coolify deploy for $APP_UUID ==="
resp=$(curl -s -m 30 -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" \
  "${BASE}/api/v1/deploy?uuid=${APP_UUID}")
echo "$resp"

duuid=$(echo "$resp" | jq -r '.deployments[0].deployment_uuid // empty')
if [ -z "$duuid" ]; then
  echo "ERROR: could not parse deployment_uuid" >&2
  exit 1
fi
echo "Deployment UUID: $duuid"

echo "=== Polling deployment status (max 30 min) ==="
for i in $(seq 1 180); do
  st=$(curl -s -m 15 -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
    "${BASE}/api/v1/deployments/${duuid}" | jq -r '.status // empty')
  echo "[$i] status=$st"
  case "$st" in
    finished) echo "Deploy succeeded."; exit 0 ;;
    failed|cancelled|canceled) echo "Deploy FAILED (status=$st)."; exit 1 ;;
  esac
  sleep 10
done
echo "ERROR: deploy timed out after 30 minutes." >&2
exit 1
