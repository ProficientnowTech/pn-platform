#!/usr/bin/env bash
# The sovereign ephemeral bootstrapper entrypoint. Phase state-machine, checkpointed + resumable + gated.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/gate.sh"; source "$HERE/lib/phases.sh"
for p in "$HERE"/phases/*.sh; do [ -e "$p" ] && source "$p"; done
CLUSTER=""; RESUME=0; DRYRUN=0
while [ $# -gt 0 ]; do case "$1" in
  --cluster) CLUSTER="$2"; shift 2;;
  --resume) RESUME=1; shift;;
  --yes) export YES=1; shift;;
  --dry-run) DRYRUN=1; shift;;
  *) echo "unknown arg: $1"; exit 2;;
esac; done
export STATE_DIR="${STATE_DIR:-/tmp/pn-bootstrap-${CLUSTER:-x}}"; mkdir -p "$STATE_DIR"
PHASES=(preflight secrets images talos foundation handoff tests cleanup)
start=0
if [ "$RESUME" = 1 ] && [ -f "$STATE_DIR/phase.json" ]; then
  last=$(sed -n 's/.*"last"[: ]*\([0-9]*\).*/\1/p' "$STATE_DIR/phase.json"); start=$(( ${last:-0} + 1 ))
fi
for i in "${!PHASES[@]}"; do
  name="${PHASES[$i]}"
  if [ "$i" -lt "$start" ]; then echo "skip phase $i ($name)"; continue; fi
  echo "start phase $i ($name)"
  [ "$DRYRUN" = 1 ] && continue
  "phase_${i}_${name}" || { echo "phase $i ($name) FAILED — resume with: $0 --cluster $CLUSTER --resume"; exit 1; }
  echo "{\"last\":$i}" > "$STATE_DIR/phase.json"
done
echo "bootstrap complete"
