# P4 — Phase-2 Hand-off (ArgoCD root + factory) + Test Suites — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` or `superpowers:executing-plans`. Steps use `- [ ]`.

**Goal:** (a) the **ArgoCD app-of-apps root** that, after kapp installs ArgoCD (P2), takes over and deploys the platform/apps **via the app-factory (P1)** ordered by `dependency-layer`; and (b) the **converge-gated test suite** that proves the cluster is *self-managing, sovereign, and workload-ready* — the go/no-go the bootstrapper's Phase 6 (P3) consumes before self-destruct.

**Architecture:** one ArgoCD root `Application` renders the platform from a values list of app entries through the **`app-factory` library chart** (P1) — each entry stamped + wave-ordered by its labels, so there is no hand-authored Application hierarchy. The test suite is a set of discrete probes (foundation / sovereignty / self-managing / workload / factory), each pass/fail, aggregated by `run-tests.sh` into a single exit code.

**Tech Stack:** ArgoCD · helm + `app-factory` (P1) · helm-unittest · kubeconform · bash + bats · kubectl/argocd.

## Global Constraints
- Repo `pn-platform` `main`; identity `Shaik Noorullah <snoorullah@proficientnow.com>`; push HTTPS + gh token.
- Paths: root/factory wiring in **`platform/root/`**; tests in **`provisioner/bootstrapper/tests/suite/`** (run by P3 Phase 6).
- The root uses the **P1 `app-factory`** (`platform/app-factory`) — NOT the deprecated `stack-orchestrator`.
- Apps are ordered ONLY by the `platform.pnats.cloud/dependency-layer` label → derived `sync-wave` (P1). No nested app hierarchy.
- The test suite is the **authoritative gate**: P3 Phase 7 self-destructs iff `run-tests.sh` exits 0.
- Sovereignty asserts are first-class tests (ESO → in-cluster Vault; zero Azure; ephemeral services gone).
- **No execution target assigned** — cluster probes run against the assigned target when one is available; execution is **gated on the on-prem-primary milestone**; no interim target. Unit-testable parts run in CI now.

---

### Task 1: The ArgoCD root — app-of-apps via the factory

**Files:** Create `platform/root/{root-app.yaml,apps/values.yaml}`; Test `platform/root/tests/root_test.yaml` (helm-unittest via a tests-consumer, as in P1)

**Interfaces:** `root-app.yaml` is the single `Application` ArgoCD applies at hand-off; it runs `platform/app-factory` with `apps/values.yaml` (the platform app entries) → renders one `Application`+`AppProject` per entry, wave-ordered.

- [ ] **Step 1:** `apps/values.yaml` — the initial platform app set as P1-schema entries (each: name/domain/version/team/tier/dependency-layer + source), spanning the layers:
```yaml
apps:
  - { name: cert-manager, domain: security,        version: v1.16.2, team: platform, tier: critical, dependency-layer: core,     source: {repoURL: ..., path: platform/cert-manager, targetRevision: main} }
  - { name: vault,        domain: security,        version: 1.21.1,  team: platform, tier: critical, dependency-layer: core,     source: {...} }   # the in-cluster Vault (P3 handoff target)
  - { name: harbor,       domain: developer-platform, version: 2.11.0, team: platform, tier: standard, dependency-layer: platform, source: {...} }
  - { name: kube-prometheus-stack, domain: monitoring, version: 65.5.1, team: platform, tier: standard, dependency-layer: platform, source: {...} }
```
- [ ] **Step 2:** `root-app.yaml` — `Application` (project `default`, sync-wave `-100`) whose source is `platform/app-factory` with `valueFiles: [../root/apps/values.yaml]`, `automated {prune,selfHeal}`.
- [ ] **Step 3: Failing test** — render the factory with `apps/values.yaml`, assert it emits the apps with monotonic waves:
```yaml
suite: root
templates: [render.yaml]     # tests-consumer includes app-factory + apps/values.yaml
tests:
  - it: cert-manager (core) gets an earlier wave than harbor (platform)
    asserts:
      - { equal: { path: "metadata.annotations['argocd.argoproj.io/sync-wave']", value: "-5" }, documentIndex: 0 }
  - it: renders one Application per app entry
    asserts: [{ hasDocuments: { count: 8 } }]     # 4 apps x (Application + AppProject)
```
- [ ] **Step 4:** `helm unittest` → PASS; `helm template platform/root | kubeconform -strict -ignore-missing-schemas -` (exit 0).
- [ ] **Step 5:** Commit — `feat(platform): ArgoCD root app-of-apps via the app-factory`

### Task 2: The test-suite harness

**Files:** Create `provisioner/bootstrapper/tests/suite/run-tests.sh`; Test `provisioner/bootstrapper/tests/suite_harness.bats`

**Interfaces:** `run-tests.sh` runs every `probes/*.sh` (each exits 0/1 + prints a line), prints a summary, exits non-zero if ANY probe fails. Consumed by P3 `phase_6_tests`.

- [ ] **Step 1: Failing test**:
```bash
@test "harness fails if any probe fails" {
  mkdir -p "$T/probes"; printf '#!/bin/sh\nexit 0\n' > "$T/probes/a.sh"; printf '#!/bin/sh\nexit 1\n' > "$T/probes/b.sh"; chmod +x "$T"/probes/*
  run run-tests.sh "$T/probes"; [ "$status" -ne 0 ]; [[ "$output" == *"FAIL b"* ]]
}
@test "harness passes if all pass" {
  mkdir -p "$T/probes"; printf '#!/bin/sh\nexit 0\n' > "$T/probes/a.sh"; chmod +x "$T"/probes/*
  run run-tests.sh "$T/probes"; [ "$status" -eq 0 ]
}
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** `run-tests.sh`: `fail=0; for p in "$1"/*.sh; do if "$p"; then echo "PASS $(basename "$p")"; else echo "FAIL $(basename "$p")"; fail=1; fi; done; exit $fail`.
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat+test(tests): suite harness (aggregate probe results)`

### Task 3: Foundation probes

**Files:** Create `tests/suite/probes/{10-cilium-l2.sh,20-csi-pvc.sh,30-eso-secret.sh}`; Test `tests/foundation_probes.bats`

**Interfaces:** each probe exits 0/1; cluster-facing but unit-tested via a mocked `kubectl`/`curl` on `PATH`.

- [ ] **Step 1:** `10-cilium-l2.sh` — the ingress VIP answers on VLAN 116 (reuse the handoff-doc method): `curl -m6 -o /dev/null -s http://$INGRESS_VIP/ -H "Host: $CANARY_HOST"` returns an HTTP status (not a timeout). `20-csi-pvc.sh` — apply a 1Gi PVC on `proxmox-zfs-r1`, `kubectl wait --for=jsonpath='{.status.phase}'=Bound --timeout=120s`, delete. `30-eso-secret.sh` — apply a canary `ExternalSecret` against `vault-backend`, assert the target Secret materialises.
- [ ] **Step 2: Failing test** — with a mock `kubectl` that returns `Bound`, `20-csi-pvc.sh` passes; with `Pending`, it fails:
```bash
@test "csi probe passes on Bound, fails on Pending" {
  PATH="$MOCK_BOUND:$PATH" run 20-csi-pvc.sh; [ "$status" -eq 0 ]
  PATH="$MOCK_PENDING:$PATH" run 20-csi-pvc.sh; [ "$status" -ne 0 ]
}
```
- [ ] **Step 3:** implement the three probes until the bats mocks pass.
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat+test(tests): foundation probes (cilium-l2 / csi-pvc / eso-secret)`

### Task 4: Sovereignty probes (the whole point)

**Files:** Create `tests/suite/probes/{40-eso-on-incluster-vault.sh,41-no-azure-dependency.sh,42-ephemeral-gone.sh}`; Test `tests/sovereignty_probes.bats`

**Interfaces:** assert the cluster ended sovereign; unit-tested against manifest/`kubectl`-output fixtures.

- [ ] **Step 1:** `40-eso-on-incluster-vault.sh` — `kubectl get clustersecretstore vault-backend -o jsonpath='{.spec.provider.vault.server}'` matches `*.vault.svc*` (in-cluster), NOT the ephemeral addr and NOT `azurekv`. `41-no-azure-dependency.sh` — no live object references AKV: `kubectl get clustersecretstores,externalsecrets -A -o yaml | grep -iE 'vault.azure.net|azurekv'` returns nothing. `42-ephemeral-gone.sh` — the `bootstrap` namespace / ephemeral Vault Service is absent.
- [ ] **Step 2: Failing test** — fixtures: an in-cluster-Vault store passes `40`; an azurekv store fails it:
```bash
@test "eso-sovereignty passes only on in-cluster vault" {
  PATH="$MOCK_INCLUSTER:$PATH" run 40-eso-on-incluster-vault.sh; [ "$status" -eq 0 ]
  PATH="$MOCK_AZUREKV:$PATH"   run 40-eso-on-incluster-vault.sh; [ "$status" -ne 0 ]
}
@test "no-azure-dependency fails when an azurekv store exists" {
  PATH="$MOCK_AZUREKV:$PATH" run 41-no-azure-dependency.sh; [ "$status" -ne 0 ]
}
```
- [ ] **Step 3:** implement the three probes until the bats fixtures pass.
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat+test(tests): sovereignty probes (eso->in-cluster vault / no-azure / ephemeral-gone)`

### Task 5: Self-managing + workload + factory probes

**Files:** Create `tests/suite/probes/{50-argocd-synced.sh,60-canary-workload.sh,70-factory-validation.sh}`; Test `tests/workload_probes.bats`

**Interfaces:** the cluster reconciles itself, runs a real workload, and rejects a bad app entry.

- [ ] **Step 1:** `50-argocd-synced.sh` — the root + every foundation/platform app is `Synced` + `Healthy` (`argocd app list -o json | jq` all green). `60-canary-workload.sh` — deploy a canary via a factory app entry, assert its pod Ready + it gets a `proxmox-zfs-r1` PV + is reachable through the ingress VIP; delete. `70-factory-validation.sh` — `helm template platform/app-factory` with a *deliberately invalid* entry (bad `tier`) **fails** (proves P1's `_validate` gate is live).
- [ ] **Step 2: Failing test**:
```bash
@test "factory-validation probe passes because a bad tier is rejected" {
  run 70-factory-validation.sh; [ "$status" -eq 0 ]      # probe expects `helm template` to FAIL on the bad entry
}
@test "argocd-synced fails when an app is Degraded" {
  PATH="$MOCK_DEGRADED:$PATH" run 50-argocd-synced.sh; [ "$status" -ne 0 ]
}
```
- [ ] **Step 3:** implement the three probes; `70` runs a real `helm template` against P1's chart with a bad entry and asserts a non-zero exit + the P1 fail-message contract.
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** Commit — `feat+test(tests): self-managing/workload/factory-validation probes`

### Task 6: Wire P3 Phase 6 + acceptance + final gate

**Files:** Create `provisioner/bootstrapper/tests/acceptance-suite.md`; Modify `provisioner/bootstrapper/orchestrator/phases/06-tests.sh` (from P3) to call `run-tests.sh`

- [ ] **Step 1:** `06-tests.sh` → `exec "$HERE/../../tests/suite/run-tests.sh" "$HERE/../../tests/suite/probes"` (its exit code is the go/no-go P3 Phase 7 consumes).
- [ ] **Step 2:** acceptance runbook (the assigned target cluster): after P3 phases 0–5, `run-tests.sh` must exit 0 → then and only then does the bootstrapper self-destruct. Enumerate each probe's expected on-cluster result.
- [ ] **Step 3: Final gate** — `helm unittest platform/root/tests-consumer`; `helm template platform/root | kubeconform -strict -ignore-missing-schemas -`; `bats provisioner/bootstrapper/tests/`; `bash -n` all probes. Commit + push.
- [ ] **Step 4:** Verify remote `main` == local `HEAD`.

---

## Self-review
- **Hand-off coverage:** the ArgoCD root renders the platform via the P1 factory, wave-ordered by dependency-layer (T1) — no nested hierarchy, matches design §3/§5.
- **Gate coverage:** harness (T2) + foundation (T3) + **sovereignty** (T4) + self-managing/workload/factory (T5) probes; wired as P3's Phase-6 go/no-go (T6). Self-destruct is gated on all-green.
- **Sovereignty is tested, not assumed:** ESO→in-cluster Vault, no-Azure, ephemeral-gone are explicit failing/ passing probes (T4).
- **Factory tie-in:** the root consumes P1 (T1) and the validation probe proves P1's render-time gate is live on-cluster (T5).
- **Placeholders:** none — root/values, harness, and every probe are complete; `source.repoURL`/versions in `apps/values.yaml` are per-cluster config filled at execution, and cluster-only asserts are the documented T6 acceptance.
- **Cluster-free testing:** factory render (helm-unittest/kubeconform), harness + every probe (bats with mocked `kubectl`/fixtures); the live cluster asserts are the T6 acceptance gate on the assigned target cluster.
