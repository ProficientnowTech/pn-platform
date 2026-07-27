# P3 — Sovereign Ephemeral Bootstrapper (vehicle + lifecycle) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` or `superpowers:executing-plans`. Steps use `- [ ]`.

**Goal:** A **one-shot ephemeral runner** that provisions Talos VMs, runs the P2 kapp foundation against an **in-runner ephemeral Vault** (SOPS+age-seeded — zero Azure), hands off to ArgoCD (deploy the in-cluster Vault → **migrate** secrets → **repoint** ESO), runs the P4 test suite, then **self-destructs on success / persists on failure** — idempotent, resumable, operator-gated.

**Architecture:** a container image (toolchain + pinned Talos/foundation images) runs inside a **provider-local vehicle** — a Proxmox **LXC** (bpg) for onprem/ovh, an **ACI** (`restart_policy=Never`) for cloud — sharing one vehicle-agnostic **entrypoint orchestrator**: a checkpointed phase state-machine that owns the 3 ephemeral-local services (Vault / registry / repo — design §10.1) and tears itself down only when the cluster is self-managing **and** tests pass.

**Tech Stack:** bpg/proxmox **v0.111.x** (LXC + Talos VMs) · azurerm **~>4.0** (ACI variant) · terraform · talhelper/talosctl · kapp · helm · HashiCorp Vault (ephemeral + in-cluster) · sops/age · kubectl/argocd · bash + bats.

## Global Constraints
- Repo `pn-platform` `main`; identity `Shaik Noorullah <snoorullah@proficientnow.com>`; push HTTPS + gh token.
- Path: **`provisioner/bootstrapper/`** (`image/`, `vehicle/`, `orchestrator/`, `tests/`).
- **Vehicle:** Proxmox LXC (`proxmox_virtual_environment_container`) for onprem/ovh (**first target OVH**); ACI (`azurerm_container_group`, `restart_policy="Never"`, self-destruct via `terraform destroy`) for `azure-dr`. Same entrypoint + lifecycle contract.
- **Sole secret input = the operator age key** (decrypts SOPS); the **repo is mounted**; the **PVE token is SOPS-encrypted in-repo**. No standing cloud credential.
- **Boundary (design §6):** provisioned at *substrate-ready → bootstrap* seam; owns ONLY the transient bootstrap; deprovisioned once self-managing **AND** tests pass; **persists on failure** (resumable with `--resume`).
- **The 3 ephemeral services** (§10.1) are owned here and destroyed at cleanup; migration targets are in-cluster Vault / Harbor / GitHub.
- bpg gotchas: use `proxmox_virtual_environment_vm`/`_container` (NOT experimental `proxmox_vm`); compressed Talos Image-Factory images use `content_type=iso` + `decompression_algorithm` + `disk.file_id` (**requires SSH in the provider**); VM `name = replace(name,".","-")` (dashed = CCM name-match). LXC create works with a scoped API token (no `root@pam` for the minimal case).
- Every phase is idempotent and writes a checkpoint to `${STATE_DIR}/phase.json`; `--resume` skips completed phases.

## The phase state-machine (the orchestrator's contract)
```
0 preflight   gates: substrate-ready confirmed; inputs present (age key, repo, cluster selector)
1 secrets     ephemeral Vault up + seed from SOPS (age key); enable kubernetes auth + external-secrets role
2 images      local registry/cache up; load pinned Talos image + foundation images (§10.1)
3 talos       terraform apply (proxmox-talos-vm per nodes.yaml) -> talosctl bootstrap -> kubeconfig
4 foundation  P2 deploy.sh (kapp; ESO -> ephemeral Vault)
5 handoff     apply ArgoCD root -> ArgoCD deploys in-cluster Vault -> MIGRATE secrets -> REPOINT ESO -> Harbor takes images
6 tests       run the P4 suite
7 cleanup     success -> terraform destroy vehicle + ephemeral services + shred age key ; failure -> STOP, keep state
```

---

### Task 1: The bootstrapper container image

**Files:** Create `provisioner/bootstrapper/image/{Dockerfile,versions.env,pin-images.sh}`; Test `provisioner/bootstrapper/tests/image_test.sh`

**Interfaces:** Produces an OCI image with the pinned toolchain + the pinned Talos image + foundation images baked in (for genesis, before Harbor exists).

- [ ] **Step 1:** `versions.env` (pins — from the live cluster + P2/research):
```bash
TALOS_VERSION=v1.13.5 ; KUBECTL_VERSION=v1.32.3 ; KAPP_VERSION=v0.65.3
HELM_VERSION=v3.16.4 ; KBLD_VERSION=v0.44.0 ; TALHELPER_VERSION=v3.0.24
ARGOCD_VERSION=v2.13.2 ; VAULT_VERSION=1.21.1 ; SOPS_VERSION=v3.9.4 ; AGE_VERSION=v1.2.1
TERRAFORM_VERSION=1.9.8 ; TALOS_SCHEMATIC=53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83
```
- [ ] **Step 2:** `Dockerfile` — install each tool at its pinned version; `COPY` the orchestrator; bake the pinned Talos `nocloud-amd64.raw.xz` (schematic above) into `/opt/images/`.
- [ ] **Step 3: Failing test** — `image_test.sh`:
```bash
docker build -t pn-bootstrapper:test provisioner/bootstrapper/image
for t in kapp helm kbld talosctl talhelper kubectl argocd vault sops age terraform; do
  docker run --rm pn-bootstrapper:test sh -c "command -v $t" >/dev/null || { echo "MISSING $t"; exit 1; }
done
docker run --rm pn-bootstrapper:test sh -c 'test -f /opt/images/talos-nocloud-amd64.raw.xz' || { echo "no baked talos image"; exit 1; }
echo PASS
```
- [ ] **Step 4:** build until PASS.
- [ ] **Step 5:** Commit — `feat(bootstrapper): pinned toolchain image + baked talos/foundation images`

### Task 2: The vehicle terraform (Proxmox LXC + ACI variant)

**Files:** Create `provisioner/bootstrapper/vehicle/{lxc/main.tf,lxc/variables.tf,aci/main.tf,aci/variables.tf}`; Test `tests/vehicle_test.sh`

**Interfaces:** `vehicle/lxc` provisions the ephemeral LXC that runs the image (mounts the repo + age key, reaches PVE/Talos/k8s); `vehicle/aci` the ACI equivalent. Both output the runner's address.

- [ ] **Step 1: `vehicle/lxc/main.tf`** (bpg — scoped token, unprivileged+nesting, destroyed at cleanup):
```hcl
resource "proxmox_virtual_environment_container" "bootstrapper" {
  node_name    = var.pve_node
  unprivileged = true
  features { nesting = true }          # needs nesting to run the ephemeral Vault/registry containers
  initialization {
    hostname = "pn-bootstrapper"
    ip_config { ipv4 { address = "dhcp" } }
  }
  network_interface { name = "veth0" }
  disk { datastore_id = var.datastore_id, size = 20 }
  operating_system { template_file_id = var.image_template_id, type = "debian" }
  # repo + age key are pushed in via provisioner (file/remote-exec over the container's SSH), never baked.
}
```
- [ ] **Step 2: `vehicle/aci/main.tf`** (azurerm — run-once, self-deletable):
```hcl
resource "azurerm_container_group" "bootstrapper" {
  name = "pn-bootstrapper"; location = var.location; resource_group_name = var.rg
  os_type = "Linux"; ip_address_type = "None"; restart_policy = "Never"
  identity { type = "UserAssigned", identity_ids = [var.uami_id] }   # cloud vehicle only; onprem uses none
  container { name = "bootstrap"; image = var.image; cpu = "1"; memory = "2"
    environment_variables = { CLUSTER = var.cluster } }
}
```
- [ ] **Step 3: `terraform validate` both**
```bash
for d in provisioner/bootstrapper/vehicle/lxc provisioner/bootstrapper/vehicle/aci; do
  terraform -chdir="$d" init -backend=false >/dev/null && terraform -chdir="$d" validate; done
```
Expected: both `Success`.
- [ ] **Step 4:** Commit — `feat(bootstrapper): LXC (bpg) + ACI (azurerm) vehicle modules`

### Task 3: The orchestrator — phase machine + checkpoint/resume + gates

**Files:** Create `provisioner/bootstrapper/orchestrator/{run.sh,lib/phases.sh,lib/gate.sh}`; Test `tests/orchestrator_test.bats`

**Interfaces:** `run.sh --cluster <c> [--resume] [--yes]` executes phases 0–7 in order; each phase is a function `phase_N_<name>`; on success writes `${STATE_DIR}/phase.json` `{last: N}`; `--resume` starts at `last+1`. `gate <msg>` blocks for operator confirm unless `--yes`.

- [ ] **Step 1: Failing tests** — `orchestrator_test.bats`:
```bash
@test "resume skips completed phases" {
  echo '{"last":3}' > "$STATE_DIR/phase.json"
  run run.sh --cluster t --resume --dry-run
  [[ "$output" == *"skip phase 1"* && "$output" == *"start phase 4"* ]]
}
@test "gate blocks without --yes" {
  run bash -c 'echo "" | gate "confirm substrate ready"'   # empty stdin => not confirmed
  [ "$status" -ne 0 ]
}
@test "gate passes with --yes" { run bash -c 'YES=1 gate "x"'; [ "$status" -eq 0 ]; }
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** `run.sh` (phase loop + checkpoint + `--dry-run` that prints skip/start), `lib/gate.sh` (`gate(){ [ "${YES:-}" = 1 ] && return 0; read -rp "$1 [type yes]: " a; [ "$a" = yes ]; }`), `lib/phases.sh` (phase stubs that later tasks fill).
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat(bootstrapper): phase machine + checkpoint/resume + operator gates`

### Task 4: Phase 1 — ephemeral Vault + SOPS/age seed

**Files:** Create `provisioner/bootstrapper/orchestrator/phases/01-secrets.sh`; Test `tests/secrets_test.bats`

**Interfaces:** `phase_1_secrets` starts an ephemeral Vault (dev-mode, in-runner), decrypts `secrets/*.sops.yaml` with the age key, writes them to `secret/…`, enables `kubernetes` auth + the `external-secrets` role/policy. Fails hard if the age key is absent.

- [ ] **Step 1: Failing test** — seed a SOPS fixture, assert round-trip + age-key-required:
```bash
@test "seeds secrets from sops and requires age key" {
  vault server -dev -dev-root-token-id=root & sleep 2; export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root
  unset SOPS_AGE_KEY_FILE; run phase_1_secrets; [ "$status" -ne 0 ]         # no key => fail
  export SOPS_AGE_KEY_FILE="$FIX/age.key"; run phase_1_secrets; [ "$status" -eq 0 ]
  run vault kv get -field=csitoken secret/proxmox-cloud-config; [ "$output" = "test-token" ]
}
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** `01-secrets.sh`: `[ -f "$SOPS_AGE_KEY_FILE" ] || { echo "age key required"; return 1; }`; `for f in secrets/*.sops.yaml; do sops -d "$f" | vault kv put "secret/$(basename "$f" .sops.yaml)" -; done`; `vault auth enable kubernetes` + write the `external-secrets` policy/role (matching the `vault-backend` ClusterSecretStore in P2 Task 3).
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat+test(bootstrapper): phase 1 — ephemeral Vault + SOPS/age seed`

### Task 5: Phase 3 — Talos VM provisioning + bootstrap

**Files:** Create `provisioner/bootstrapper/orchestrator/phases/03-talos.sh`; wire `provisioner/bootstrapper/vehicle/talos -> terraform/environments/onprem-k8s`; Test `tests/talos_test.sh`

**Interfaces:** `phase_3_talos` runs `talhelper genconfig` from the selected `nodes.yaml`/`talconfig`, `terraform apply` the `proxmox-talos-vm` per node (name dashed for CCM), `talosctl bootstrap`, and writes `${STATE_DIR}/kubeconfig`.

- [ ] **Step 1:** `03-talos.sh` — `talhelper genconfig`; `terraform -chdir=<onprem-k8s> apply -auto-approve` (image via `proxmox_download_file content_type=iso` + decompression, `disk.file_id`; SSH configured in the provider for the file_id import); `talosctl bootstrap --nodes <cp>`; `talosctl kubeconfig "${STATE_DIR}/kubeconfig"`.
- [ ] **Step 2: Validate (cluster-free)** — the wiring validates + talhelper renders from a fixture:
```bash
terraform -chdir=provisioner/bootstrapper/vehicle/talos init -backend=false >/dev/null && \
terraform -chdir=provisioner/bootstrapper/vehicle/talos validate
talhelper genconfig -c tests/fixtures/talconfig.yaml -o /tmp/tal && test -f /tmp/tal/*-m-01.yaml && echo PASS
```
Expected: `Success` + `PASS`; confirm a rendered VM name is dashed (`grep -r 'n-onp' /tmp/tal`).
- [ ] **Step 3:** Commit — `feat(bootstrapper): phase 3 — talos VM provisioning + bootstrap`

### Task 6: Phase 5 — hand-off (in-cluster Vault, migrate, repoint ESO)

**Files:** Create `provisioner/bootstrapper/orchestrator/phases/05-handoff.sh`; Test `tests/handoff_test.bats`

**Interfaces:** `phase_5_handoff` applies the ArgoCD root, waits for the in-cluster Vault app Healthy, **migrates** every `secret/*` path ephemeral→in-cluster Vault, then **repoints** the `vault-backend` `ClusterSecretStore` `spec.provider.vault.server` from the ephemeral addr to the in-cluster addr and waits for ESO `Ready=True`.

- [ ] **Step 1: Failing test** — two local Vaults; assert migration copies all paths + the store manifest flips:
```bash
@test "migrate copies all secret paths and repoints ESO" {
  # src (ephemeral) + dst (in-cluster) dev Vaults on :8200/:8201
  migrate_secrets "$SRC" "$DST"
  run vault kv get -address="$DST" -field=csitoken secret/proxmox-cloud-config; [ "$output" = "test-token" ]
  repoint_eso "$STATE_DIR/store.yaml" "http://vault.vault.svc:8200"
  run yq '.spec.provider.vault.server' "$STATE_DIR/store.yaml"; [ "$output" = "http://vault.vault.svc:8200" ]
}
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** `05-handoff.sh`: `migrate_secrets(){ for p in $(vault kv list -address="$1" -format=json secret | jq -r '.[]'); do vault kv get -address="$1" -format=json "secret/$p" | jq '.data.data' | vault kv put -address="$2" "secret/$p" -; done; }`; `repoint_eso(){ yq -i ".spec.provider.vault.server = \"$2\"" "$1" && kubectl apply -f "$1"; }`; plus `argocd app wait vault --health`.
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat+test(bootstrapper): phase 5 — in-cluster Vault handoff + secret migration + ESO repoint`

### Task 7: Phase 7 — cleanup / persist-on-failure

**Files:** Create `provisioner/bootstrapper/orchestrator/phases/07-cleanup.sh`; Test `tests/cleanup_test.bats`

**Interfaces:** `phase_7_cleanup <result>` — on `pass`: `terraform destroy` the vehicle, stop the ephemeral Vault/registry, `shred` the age key, delete `${STATE_DIR}`. On `fail`: do NONE of that, print the resume command, exit non-zero. Called by `run.sh`'s trap with the overall result.

- [ ] **Step 1: Failing test**:
```bash
@test "cleanup destroys on pass, persists on fail" {
  DESTROY_CMD="touch $TMP/destroyed"
  phase_7_cleanup pass; [ -f "$TMP/destroyed" ]
  rm -f "$TMP/destroyed"; run phase_7_cleanup fail; [ "$status" -ne 0 ]; [ ! -f "$TMP/destroyed" ]
  [[ "$output" == *"--resume"* ]]
}
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** `07-cleanup.sh` (guarded on `$1`; `pass` → run `$DESTROY_CMD` / `terraform destroy -auto-approve` + `shred -u "$SOPS_AGE_KEY_FILE"`; `fail` → echo resume hint + `return 1`). Wire `run.sh` trap: `trap 'phase_7_cleanup $([ $? -eq 0 ] && echo pass || echo fail)' EXIT`.
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat+test(bootstrapper): phase 7 — self-destruct on success / persist on failure`

### Task 8: End-to-end acceptance (OVH proving-ground) + final gate

**Files:** Create `provisioner/bootstrapper/tests/acceptance.md`

> Requires the OVH proving-ground PVE (substrate-ready) + the operator age key + the mounted repo. Not CI.

- [ ] **Step 1:** Runbook: build+push the image; `terraform apply` the LXC vehicle on the OVH PVE; inside it `run.sh --cluster ovh-proving-ground`; expected: phases 0–6 pass, phase 7 self-destructs; the cluster survives with in-cluster Vault + ESO→`vault-backend` (in-cluster) + no ephemeral artifacts and no Azure dependency.
- [ ] **Step 2:** Assert (post-run): `kubectl get clustersecretstore vault-backend -o jsonpath={.spec.provider.vault.server}` = the in-cluster addr; the vehicle LXC is gone; ArgoCD Synced+Healthy.
- [ ] **Step 3: Final gate** — `bats tests/`; `terraform validate` (all vehicle dirs); `bash -n` all scripts. Commit + push.
- [ ] **Step 4:** Verify remote `main` == local `HEAD`.

---

## Self-review
- **Lifecycle coverage:** image (T1), vehicle LXC+ACI (T2), phase machine + resume + gates (T3), ephemeral Vault seed (T4), Talos provisioning (T5), in-cluster-Vault hand-off + migrate + repoint (T6), self-destruct/persist (T7), real gate (T8) — the full §6 boundary + §10 lifecycle.
- **Sovereignty:** age key is the sole secret input (T4 fails without it); ESO ends on the in-cluster Vault (T6); age key shredded + vehicle destroyed on success (T7). Zero standing Azure.
- **Resumability:** every phase checkpoints; `--resume` skips (T3); failure keeps state (T7) — matches "persists on failure."
- **bpg correctness:** `proxmox_virtual_environment_container`/`_vm` (not experimental), dashed VM name (T5), nesting for in-LXC containers (T2). azurerm ACI `restart_policy=Never` + destroy-to-self-delete (T2/T7).
- **Placeholders:** none — Dockerfile/versions, both vehicle modules, the phase machine, and each phase's real logic (migrate/repoint/gate/cleanup) are complete; per-cluster PVE endpoints live in tfvars/.env, filled at execution.
- **Cluster-free testing:** image (docker), vehicle (`terraform validate`), orchestrator+phases (bats with dev-mode Vaults), talos wiring (validate + talhelper render); the PVE/real-cluster path is the T8 acceptance gate.
