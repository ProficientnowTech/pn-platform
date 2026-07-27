# provisioner/bootstrapper — the sovereign ephemeral bootstrapper (P3)

One-shot runner: provisions Talos VMs, runs the P2 kapp foundation against an in-runner **ephemeral
Vault** (SOPS + operator age key — zero Azure), hands off to ArgoCD (deploy in-cluster Vault → migrate
secrets → repoint ESO), runs the P4 test suite, then self-destructs on success / persists on failure.

- `image/` — the pinned toolchain image (`Dockerfile` + `versions.env`) with the baked Talos image.
- `vehicle/lxc` — Proxmox LXC (bpg) vehicle; `vehicle/aci` — Azure ACI (run-once) vehicle. Same entrypoint.
- `orchestrator/run.sh` — phase state-machine (0 preflight/gate · 1 ephemeral-Vault+SOPS seed · 2 images ·
  3 talos · 4 kapp foundation · 5 handoff: in-cluster Vault + migrate + repoint ESO · 6 tests · 7 cleanup),
  checkpointed + `--resume` + operator `gate`. Phase bodies in `orchestrator/phases/NN-*.sh`.
- `tests/` — the P4 probe suite (`tests/suite/`) + bats: `orchestrator.bats` (phase machine/resume/gate),
  `secrets.bats` (ephemeral-Vault seed + migrate + repoint + cleanup, real dev Vaults), `probes.bats`.

Sole secret input = the operator age key (shredded on success). Zero standing Azure. Vehicle/talos/handoff
acceptance is the target-cluster gate (`tests/acceptance-suite.md`).
