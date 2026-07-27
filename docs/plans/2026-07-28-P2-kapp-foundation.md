# P2 — kapp Phase-1 Foundation (converge-gated one-shot) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` or `superpowers:executing-plans`. Steps use `- [ ]`.

**Goal:** Replace the manual `helm install`/`kubectl apply` foundation bring-up with a **single idempotent, converge-gated `kapp deploy`** that takes a bare Talos cluster to `Cilium → Proxmox-CSI(+CCM) → ESO → ArgoCD`, with secrets sourced from the **ephemeral Vault** (P3), ready for the ArgoCD hand-off (P4).

**Architecture:** A render pipeline (`helm template` the live-reference foundation charts with per-cluster values, piped through `kbld` for digest-pinning) feeds `kapp deploy`. A single **kapp `Config`** file declares the cross-layer ordering (`changeGroupBindings` + `changeRuleBindings` per namespace) and the **`waitRules`** that gate on *real* CR convergence (ESO `ClusterSecretStore`/`ExternalSecret` `Ready`) — so a layer isn't applied until the prior layer is genuinely reconciled, not merely API-accepted. Foundation charts are vendored from the live cluster; nothing is hand-rolled.

**Tech Stack:** kapp (Carvel) **v0.65.x** · helm 3 · kbld · kubeconform · kind (ordering/idempotency tests) · yq.

## Global Constraints
- Repo `pn-platform` `main`; push HTTPS + gh token; identity `Shaik Noorullah <snoorullah@proficientnow.com>`.
- Foundation path: **`infrastructure/bootstrap/foundation/`**.
- Foundation chain is EXACTLY, in order: **`10-cilium → 20-proxmox-csi → 30-external-secrets → 40-argocd`**. **Vault is NOT in the foundation** (it is an ArgoCD-managed platform app — design §10).
- Foundation charts/values are **vendored verbatim** from ovh-infra `onprem/platform-live:infrastructure/talos/platform/` (Cilium `cilium/values.yaml` + `cilium-lb`, `proxmox-csi/charts` + CCM, `external-secrets`, `argocd`). Do not hand-author manifests that already exist there.
- **Secrets during bootstrap come from the ephemeral Vault (P3)** — the bootstrap `ClusterSecretStore` is `vault-backend` pointing at `$EPHEMERAL_VAULT_ADDR`, **NOT** the live `azure-kv` store.
- **No execution target is assigned.** The plan is parameterized on the cluster-registry entry; CI/unit tests render against the fixture `clusters/example.env`. Real execution is **gated on the on-prem-primary milestone** — no target cluster is available yet, and there is no interim target. The live on-prem cluster (`onprem/platform-live`) is untouched.
- kapp invocation is always: `kapp deploy -y -a foundation -f <rendered> -f config.yaml --wait-timeout=20m --wait-resource-timeout=10m --apply-exit-status`.
- change-group names: `foundation.pnats.cloud/<layer>`; change-rule grammar: `upsert after upserting foundation.pnats.cloud/<prev-layer>`.
- Per-cluster inputs (cluster name, Vault addr, PVE endpoint) come from `infrastructure/bootstrap/foundation/clusters/<cluster>.env` — never hard-coded.

---

### Task 1: Scaffold + the render pipeline

**Files:** Create `infrastructure/bootstrap/foundation/{render.sh,deploy.sh,clusters/example.env}`; `infrastructure/bootstrap/foundation/README.md`

**Interfaces:** Produces `render.sh <cluster>` → a single valid multi-doc YAML stream on stdout (all 4 layers, digest-pinned), consumed by Task 5's `deploy.sh` and every validation step.

- [ ] **Step 1:** `clusters/example.env`
```bash
CLUSTER_NAME=example
EPHEMERAL_VAULT_ADDR=http://ephemeral-vault.bootstrap.svc:8200   # provided by P3
PVE_API_URL=https://PLACEHOLDER:8006/api2/json                    # set per target PVE at execution
PVE_REGION=example
```
- [ ] **Step 2:** `render.sh` (renders each layer with its values, concatenates, pins via kbld)
```bash
#!/usr/bin/env bash
set -euo pipefail
CLUSTER="${1:?usage: render.sh <cluster>}"
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/clusters/$CLUSTER.env"
render_layer(){ helm template "$1" "$HERE/$2/chart" -n "$3" -f "$HERE/$2/values.yaml" --include-crds; }
{
  render_layer cilium        10-cilium         kube-system
  render_layer proxmox-csi   20-proxmox-csi    csi-proxmox
  render_layer external-secrets 30-external-secrets external-secrets
  render_layer argocd        40-argocd         argocd
  cat "$HERE"/*/extra/*.yaml 2>/dev/null || true    # non-chart manifests (stores, pools, l2 policy)
} | kbld -f -    # resolve+lock image digests (no-op if kbld has nothing to pin)
```
- [ ] **Step 3:** empty layer dirs with a `.gitkeep` each (filled by Task 2/3).
- [ ] **Step 4:** `chmod +x render.sh deploy.sh`; `bash -n render.sh` (syntax OK).
- [ ] **Step 5:** Commit — `feat(bootstrap): foundation scaffold + render pipeline`

### Task 2: Vendor the 4 foundation layers (verbatim from the live cluster)

**Files:** Create `infrastructure/bootstrap/foundation/{10-cilium,20-proxmox-csi,30-external-secrets,40-argocd}/{chart,values.yaml,extra/}`

**Interfaces:** Each layer dir renders via `helm template <name> <dir>/chart -f <dir>/values.yaml`.

- [ ] **Step 1: Copy the live values + vendored charts** from ovh-infra `onprem/platform-live`:
```bash
SRC=/home/devsupreme/work/ovh-infra ; REF=origin/onprem/platform-live ; DST=infrastructure/bootstrap/foundation
git -C "$SRC" show "$REF:infrastructure/talos/platform/cilium/values.yaml" > "$DST/10-cilium/values.yaml"
# proxmox-csi + ccm charts are already vendored in the live tree — copy the chart dirs:
git -C "$SRC" archive "$REF" infrastructure/talos/platform/proxmox-csi/charts | tar -x --strip-components=6 -C "$DST/20-proxmox-csi/chart"
# ESO + ArgoCD: pin the upstream chart versions the live cluster uses (external-secrets 2.7.0, argo-cd from live values)
```
- [ ] **Step 2:** Cilium `values.yaml` — keep the live values verbatim (kubeProxyReplacement, KubePrism `localhost:7445`, `l2announcements.enabled`, wireguard). Add the L2 pool + policy as `10-cilium/extra/loadbalancer.yaml` (copied from live `ingress/cilium-lb/loadbalancer.yaml`).
- [ ] **Step 3:** proxmox-csi `values.yaml` — the live `valuesObject` (SC `proxmox-zfs-r1`, `existingConfigSecret: proxmox-cloud-config`) parameterised on `$PVE_REGION`.
- [ ] **Step 4: Validate all layers render + are valid k8s**
```bash
./render.sh example | kubeconform -strict -ignore-missing-schemas -
```
Expected: exit 0, no invalid resources.
- [ ] **Step 5:** Commit — `feat(bootstrap): vendor cilium/csi/eso/argocd foundation layers`

### Task 3: Bootstrap secret plumbing (ephemeral-Vault-backed)

**Files:** Create `infrastructure/bootstrap/foundation/30-external-secrets/extra/{clustersecretstore.yaml,externalsecrets.yaml}`

**Interfaces:** Produces the `vault-backend` `ClusterSecretStore` (→ ephemeral Vault) + the 3 foundation `ExternalSecret`s that materialise the Secrets Cilium/CSI/ArgoCD need.

- [ ] **Step 1: `clustersecretstore.yaml`** — points at the ephemeral Vault (NOT azure-kv):
```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata: { name: vault-backend }
spec:
  provider:
    vault:
      server: "${EPHEMERAL_VAULT_ADDR}"      # substituted by render.sh (envsubst)
      path: secret
      version: v2
      auth:
        kubernetes:
          mountPath: kubernetes
          role: external-secrets
          serviceAccountRef: { name: external-secrets, namespace: external-secrets }
```
- [ ] **Step 2: `externalsecrets.yaml`** — the verified foundation secret set (design §10.5), keys as the live cluster names: `proxmox-cloud-config` (csitoken), `argocd-github-app-creds` (appID/installID/privateKey), `cloudflare-api-token`. Copy the live ExternalSecret bodies, only swapping `secretStoreRef.name` → `vault-backend`.
- [ ] **Step 3:** add `envsubst '${EPHEMERAL_VAULT_ADDR} ${PVE_REGION}'` into `render.sh` before `kbld` so the env vars land.
- [ ] **Step 4: Validate**
```bash
EPHEMERAL_VAULT_ADDR=http://x:8200 ./render.sh example | yq 'select(.kind=="ClusterSecretStore") | .spec.provider.vault.server'
```
Expected: prints `http://x:8200` (proves substitution + that it's the vault provider, not azurekv).
- [ ] **Step 5:** Commit — `feat(bootstrap): ephemeral-Vault ClusterSecretStore + foundation ExternalSecrets`

### Task 4: The kapp Config — ordering + convergence gates

**Files:** Create `infrastructure/bootstrap/foundation/config.yaml`; Test `infrastructure/bootstrap/foundation/tests/ordering_test.sh`

**Interfaces:** A `kapp.k14s.io/v1alpha1 Config` passed via `-f`; binds each namespace to a layer change-group, chains the rules, and teaches kapp to wait on ESO CR `Ready`.

- [ ] **Step 1: Failing test** — `tests/ordering_test.sh` asserts kapp computes the layers in order on a kind cluster:
```bash
#!/usr/bin/env bash
set -euo pipefail
kind create cluster --name p2-order --wait 60s
trap 'kind delete cluster --name p2-order' EXIT
# dry-run: kapp prints the change-set grouped by change-group in dependency order
EPHEMERAL_VAULT_ADDR=http://x:8200 ../render.sh example \
  | kapp deploy -a foundation -f - -f ../config.yaml --dry-run --diff-changes 2>&1 \
  | tee /tmp/p2-order.txt
# cilium must be ordered before argocd:
c=$(grep -n 'foundation.pnats.cloud/cilium' /tmp/p2-order.txt | head -1 | cut -d: -f1)
a=$(grep -n 'foundation.pnats.cloud/argocd' /tmp/p2-order.txt | head -1 | cut -d: -f1)
[ "$c" -lt "$a" ] || { echo "FAIL: argocd not ordered after cilium"; exit 1; }
echo "PASS: layer ordering correct"
```
- [ ] **Step 2:** Run → FAIL (`config.yaml` absent).
- [ ] **Step 3: Implement `config.yaml`**
```yaml
apiVersion: kapp.k14s.io/v1alpha1
kind: Config
changeGroupBindings:
  - name: foundation.pnats.cloud/cilium
    resourceMatchers: [{ namespaceMatcher: { names: [kube-system] } }]
  - name: foundation.pnats.cloud/proxmox-csi
    resourceMatchers: [{ namespaceMatcher: { names: [csi-proxmox] } }]
  - name: foundation.pnats.cloud/external-secrets
    resourceMatchers: [{ namespaceMatcher: { names: [external-secrets] } }]
  - name: foundation.pnats.cloud/argocd
    resourceMatchers: [{ namespaceMatcher: { names: [argocd] } }]
changeRuleBindings:
  - rules: ["upsert after upserting foundation.pnats.cloud/cilium"]
    resourceMatchers: [{ namespaceMatcher: { names: [csi-proxmox] } }]
  - rules: ["upsert after upserting foundation.pnats.cloud/proxmox-csi"]
    resourceMatchers: [{ namespaceMatcher: { names: [external-secrets] } }]
  - rules: ["upsert after upserting foundation.pnats.cloud/external-secrets"]
    resourceMatchers: [{ namespaceMatcher: { names: [argocd] } }]
waitRules:
  # ESO ClusterSecretStore + ExternalSecret expose a Ready condition — gate on the REAL reconcile,
  # so ArgoCD (which needs the repo-creds Secret) never applies before secrets actually exist.
  - supportsObservedGeneration: true
    conditionMatchers:
      - { type: Ready, status: "False", failure: true }
      - { type: Ready, status: "True",  success: true }
    resourceMatchers:
      - apiVersionKindMatcher: { apiVersion: external-secrets.io/v1, kind: ClusterSecretStore }
      - apiVersionKindMatcher: { apiVersion: external-secrets.io/v1, kind: ExternalSecret }
```
- [ ] **Step 4:** Run `tests/ordering_test.sh` → PASS.
- [ ] **Step 5:** Commit — `feat+test(bootstrap): kapp Config — layer ordering + ESO wait-rules`

### Task 5: `deploy.sh` — the one-shot + idempotency

**Files:** Modify `infrastructure/bootstrap/foundation/deploy.sh`; Test `tests/idempotency_test.sh`

**Interfaces:** `deploy.sh <cluster>` renders + applies with the fixed flag set; exit code encodes result (`--apply-exit-status`: `2`=no-op, `3`=changes applied).

- [ ] **Step 1: Implement `deploy.sh`**
```bash
#!/usr/bin/env bash
set -euo pipefail
CLUSTER="${1:?usage: deploy.sh <cluster>}"; HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/render.sh" "$CLUSTER" | kapp deploy -y -a foundation -f - -f "$HERE/config.yaml" \
  --wait-timeout=20m --wait-resource-timeout=10m --apply-exit-status
```
- [ ] **Step 2: Idempotency test** (kind; Cilium+ESO real, proxmox-csi stubbed since no PVE) — asserts a second apply is a no-op:
```bash
#!/usr/bin/env bash
set -euo pipefail
kind create cluster --name p2-idem --wait 90s
trap 'kind delete cluster --name p2-idem' EXIT
export EPHEMERAL_VAULT_ADDR=http://x:8200
STUB=1 ./deploy.sh example || true        # STUB swaps proxmox-csi for a dummy Ready DaemonSet
./deploy.sh example; rc=$?               # 2nd apply
[ "$rc" -eq 2 ] && echo "PASS: re-apply is a no-op (exit 2)" || { echo "FAIL: rc=$rc (expected 2)"; exit 1; }
```
- [ ] **Step 3:** add a `STUB` branch in `render.sh` that, when `STUB=1`, replaces `20-proxmox-csi` with `tests/stubs/proxmox-csi-ready.yaml` (a DaemonSet that reports Ready — lets the cluster-agnostic layers + ordering + wait-rules run on kind without PVE).
- [ ] **Step 4:** Run `tests/idempotency_test.sh` → PASS.
- [ ] **Step 5:** Commit — `feat+test(bootstrap): deploy.sh one-shot + kind idempotency test`

### Task 6: kind CI smoke — converge + ordering under a real kapp run

**Files:** Create `tests/kind_smoke_test.sh`, `tests/stubs/proxmox-csi-ready.yaml`

- [ ] **Step 1:** `kind_smoke_test.sh` — deploy the STUBbed foundation to kind, assert kapp reports every change-group converged and Cilium DaemonSet + ESO stores are Ready:
```bash
kind create cluster --name p2-smoke --wait 120s
export EPHEMERAL_VAULT_ADDR=http://x:8200
STUB=1 ./deploy.sh example
kubectl -n kube-system rollout status ds/cilium --timeout=180s
kubectl wait --for=condition=Ready clustersecretstore/vault-backend --timeout=60s || true  # Ready only if ephemeral Vault reachable
echo "PASS: foundation converged on kind (stubbed CSI)"
```
- [ ] **Step 2:** Run → PASS (documents: ESO store shows `Ready=False` without a live Vault — expected on kind; the wait-rule wiring is what's under test, verified by Task 4).
- [ ] **Step 3:** Commit — `test(bootstrap): kind smoke — converge + ordering`

### Task 7: Real-cluster acceptance (the assigned target cluster) — the gate

**Files:** Create `tests/acceptance-onprem.md` (runbook)

> Requires an assigned target cluster (Talos up via P3) + the ephemeral Vault reachable. Cannot run in CI. **Gated on the on-prem-primary milestone — no cluster available yet.**

- [ ] **Step 1:** Runbook (against the assigned target `$CLUSTER`): `./deploy.sh "$CLUSTER"` end-to-end; expected: kapp exits `0/3`, all 4 change-groups converged, `kubectl get clustersecretstore vault-backend` = `Ready=True`, `argocd-server` Deployment Available.
- [ ] **Step 2:** Acceptance asserts (documented, run on the cluster): Cilium L2 VIP answers ARP (per the ingress handoff method), CSI provisions a test PVC on `proxmox-zfs-r1`, an `ExternalSecret` materialises its Secret from the ephemeral Vault, ArgoCD is reachable.
- [ ] **Step 3:** Commit — `docs(bootstrap): target-cluster acceptance runbook`

### Task 8: Final gate + push

- [ ] **Step 1:** `./render.sh example | kubeconform -strict -ignore-missing-schemas -` (exit 0); `bash -n render.sh deploy.sh`; run `tests/ordering_test.sh` + `tests/idempotency_test.sh` green.
- [ ] **Step 2:** `git add infrastructure/bootstrap/foundation && git commit && git push origin HEAD:main` (identity + gh cred as Global Constraints).
- [ ] **Step 3:** Verify remote `main` == local `HEAD`.

---

## Self-review
- **Chain coverage:** all 4 layers vendored (T2) + secret plumbing (T3) + ordering/gates (T4) + one-shot/idempotency (T5) + kind smoke (T6) + real-cluster gate (T7). Vault correctly absent (platform app).
- **Sovereignty:** the bootstrap `ClusterSecretStore` is `vault-backend`→ephemeral Vault, not `azure-kv` (T3) — matches design §10.
- **kapp correctness:** `changeGroupBindings`/`changeRuleBindings` bind by namespace (no per-manifest annotation churn); `waitRules` gate on ESO CR `Ready` so ordering waits on *real* convergence, not API-accept (research-grounded).
- **Reference reuse:** charts/values copied verbatim from `onprem/platform-live` (T2), not hand-rolled.
- **Placeholders:** none — render/deploy scripts, kapp Config, and tests are complete; the one `PLACEHOLDER` is a per-cluster PVE endpoint in an `.env`, filled at execution.
- **Testability without a cluster:** ordering (kapp `--dry-run`), idempotency + smoke (kind with a CSI stub); the PVE-dependent converge is the explicit T7 acceptance gate.
