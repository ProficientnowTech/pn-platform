# phase 3 — talhelper genconfig -> terraform apply (proxmox-talos-vm per node) -> talosctl bootstrap -> kubeconfig.
phase_3_talos(){
  talhelper genconfig -c "${TALCONFIG:?set TALCONFIG}" -o "${STATE_DIR}/talos"
  terraform -chdir="${TALOS_TF_DIR:?set TALOS_TF_DIR}" apply -auto-approve
  talosctl bootstrap --nodes "${CP_NODE:?set CP_NODE}"
  talosctl kubeconfig "${STATE_DIR}/kubeconfig"
  echo "talos bootstrapped"
}
