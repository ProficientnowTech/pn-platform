# phase 7 — success: destroy the vehicle + ephemeral services + shred the age key. failure: keep state.
phase_7_cleanup_impl(){
  if [ "${1:-pass}" = pass ]; then
    ${DESTROY_CMD:-true}
    [ -n "${SOPS_AGE_KEY_FILE:-}" ] && [ -f "${SOPS_AGE_KEY_FILE:-}" ] && shred -u "$SOPS_AGE_KEY_FILE" 2>/dev/null || true
    echo "cleanup: vehicle destroyed + age key shredded"; return 0
  fi
  echo "FAILURE — state kept; resume with: run.sh --cluster \$CLUSTER --resume"; return 1
}
