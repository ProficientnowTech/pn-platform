# P3 acceptance — end-to-end on the target cluster. Not CI.

Requires: PVE substrate-ready + the operator age key + the mounted repo. **Gated on the on-prem-primary milestone.**

1. `docker build` + push `image/` (pinned toolchain + baked Talos image).
2. `terraform apply` `vehicle/lxc` on the target PVE (or `vehicle/aci` for azure-dr).
3. Inside the vehicle: `orchestrator/run.sh --cluster <CLUSTER>`.

Expected: phases 0–6 pass, phase 7 self-destructs. Post-run the cluster survives with the **in-cluster
Vault** + ESO `vault-backend` pointing in-cluster + **no ephemeral artifacts and no Azure dependency**;
the vehicle LXC/ACI is gone; ArgoCD Synced+Healthy. On failure the state persists (`--resume`).
