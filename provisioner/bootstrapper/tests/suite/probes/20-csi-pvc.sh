#!/usr/bin/env bash
set -uo pipefail
NS="${PROBE_NS:-default}"
kubectl apply -f - >/dev/null 2>&1 <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: csi-probe, namespace: ${NS} }
spec: { accessModes: [ReadWriteOnce], storageClassName: proxmox-zfs-r1, resources: { requests: { storage: 1Gi } } }
EOF
phase=$(kubectl -n "$NS" get pvc csi-probe -o jsonpath='{.status.phase}' 2>/dev/null)
kubectl -n "$NS" delete pvc csi-probe >/dev/null 2>&1 || true
[ "$phase" = Bound ] && { echo "csi-pvc: Bound"; exit 0; } || { echo "csi-pvc: ${phase:-unbound}"; exit 1; }
