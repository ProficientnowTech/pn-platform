# P0 — pn-platform Tree Reconciliation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`. Steps use `- [ ]` checkboxes.

**Goal:** Evolve the pn-platform tree to the approved structure — delete the rejected api-CLI monorepo, migrate `business/` → `application/`, and scaffold `platform/{clusters,app-factory,bootstrap}` + `cli/` — while keeping the repo lint/kubeconform-green and the *existing* factory intact until P1 rebuilds it.

**Architecture:** Pure repo surgery on `pn-platform` `main`. Delete clearly-rejected trees; `git mv` the app + CI (history preserved); scaffold new dirs with real skeletons (registry files are complete data; the app-factory chart is a stub P1 fills). The old `platform/{stacks,stack-orchestrator,project-chart}` **stay as reference** until P1/P2 replace them. Each task ends with a tree/lint gate + a commit.

**Tech Stack:** git, `helm lint/template`, `kubeconform`, `yamllint`. No application code.

## Global Constraints
- Repo `ProficientNowTech/pn-platform`, branch `main`. Push over HTTPS with the gh work token; commit identity **`Shaik Noorullah <snoorullah@proficientnow.com>`**.
- **Do NOT delete** `platform/{stacks,stack-orchestrator,project-chart,bootstrap,hooks}` — P1 rebuilds them; deleting now would strand the reference.
- **Preserve history** for moved files (`git mv`, never delete+recreate).
- The untracked generated artifacts (`.pi/`, `platform/bootstrap/.generated/`, `platform/bootstrap/secrets/`, vendored `charts/`) must **stay untracked** — never `git add` them; gitignore them in Task 7.
- Cluster registry file contents come **verbatim** from `docs/design/directory-structure-and-cluster-registry.md` §4 + the OVH time-box from `org-stack-primary-site-roadmap`.

---

### Task 1: Safety tag the pre-reconciliation state

**Files:** none (git ref only)

- [ ] **Step 1: Tag current main + push**
```bash
cd /home/devsupreme/work/pn-platform
git tag -a archive/pre-P0-reconciliation -m "pn-platform tree before P0 reconciliation"
git -c credential.helper='!gh auth git-credential' push https://github.com/ProficientnowTech/pn-platform.git refs/tags/archive/pre-P0-reconciliation
```
- [ ] **Step 2: Verify** — `git ls-remote --tags origin archive/pre-P0-reconciliation` returns a SHA. Everything below is recoverable from it.

### Task 2: Delete the rejected api-CLI monorepo

**Files:** Delete `api/`, `config/`, `container-orchestration/`, `v0.2.0/`, `go.mod`

- [ ] **Step 1: Confirm these are the api-CLI monorepo (not referenced by platform/)**
```bash
grep -rIl -E 'api/|container-orchestration/|config/packages' platform/ application/ 2>/dev/null || echo "no platform/app refs — safe"
```
Expected: `no platform/app refs — safe` (the factory doesn't consume them).
- [ ] **Step 2: Remove**
```bash
git rm -r -q api config container-orchestration v0.2.0 go.mod
```
- [ ] **Step 3: Verify tree** — `ls` shows none of them; `git status --porcelain | grep '^D'` lists exactly those paths.
- [ ] **Step 4: Commit**
```bash
git -c user.email=snoorullah@proficientnow.com -c user.name="Shaik Noorullah" commit -q -m "refactor: delete the rejected api-CLI monorepo (api/ config/ container-orchestration/ v0.2.0/ go.mod)"
```

### Task 3: Delete speculative platform bits

**Files:** Delete `platform/tenant-clusters/`; delete `scripts/bootstrap.sh` **iff** it is the Kubespray 3-phase script

- [ ] **Step 1: Inspect scripts/bootstrap.sh**
```bash
head -20 scripts/bootstrap.sh 2>/dev/null | grep -iE 'kubespray|microk8s' && echo "IS kubespray -> delete" || echo "NOT kubespray -> KEEP, skip its deletion"
```
- [ ] **Step 2: Remove tenant-clusters (KubeVirt, speculative) + the Kubespray script if matched**
```bash
git rm -r -q platform/tenant-clusters
# only if Step 1 said "IS kubespray":
git rm -q scripts/bootstrap.sh
```
- [ ] **Step 3: Verify** — `test ! -d platform/tenant-clusters && echo gone`.
- [ ] **Step 4: Commit**
```bash
git -c user.email=snoorullah@proficientnow.com -c user.name="Shaik Noorullah" commit -q -m "refactor: drop speculative platform/tenant-clusters (KubeVirt) + Kubespray bootstrap script"
```

### Task 4: Migrate `business/` → `application/`

**Files:** `git mv business/apps/pnats → application/pnats`; `business/ci → application/ci`; `business/pipelines → platform/stacks/developer-platform/pipelines`

- [ ] **Step 1: Create targets + move (history-preserving)**
```bash
mkdir -p application platform/stacks/developer-platform
git mv business/apps/pnats application/pnats
git mv business/ci application/ci
git mv business/pipelines platform/stacks/developer-platform/pipelines
# move remaining business/ files (environments, .keep) then remove the empty dir
git mv business/environments application/environments 2>/dev/null || true
git rm -r -q business 2>/dev/null || true
```
- [ ] **Step 2: Verify no dangling refs to the old paths**
```bash
grep -rIl 'business/apps\|business/ci\|business/pipelines' platform/ application/ 2>/dev/null && echo "FIX these refs" || echo "no dangling refs"
```
Fix any hit by pointing it at the new path.
- [ ] **Step 3: Verify** — `test -d application/pnats && test -d application/ci && echo moved`.
- [ ] **Step 4: Commit**
```bash
git -c user.email=snoorullah@proficientnow.com -c user.name="Shaik Noorullah" commit -q -m "refactor: migrate business/ -> application/ (pnats + ci) and pipelines -> developer-platform stack"
```

### Task 5: Scaffold `platform/clusters/` (the registry — real data)

**Files:** Create `platform/clusters/{onprem-primary,contabo-standby,azure-dr,ovh-proving-ground}.yaml` + `platform/clusters/README.md`

- [ ] **Step 1: Write the 4 registry files** (verbatim from the directory-structure design §4)
```bash
mkdir -p platform/clusters
cat > platform/clusters/onprem-primary.yaml <<'EOF'
name:        onprem-primary
provider:    onprem
role:        primary
region:      ap-south-2a
lifecycle:   {status: building}
destination: {name: in-cluster}
envs:        [dev, staging, prod, preview]
stacks:      {include: all}
values:      {ref: values/onprem-primary/}
replication: {role: source, targets: [contabo-standby, azure-dr]}
EOF
cat > platform/clusters/contabo-standby.yaml <<'EOF'
name:        contabo-standby
provider:    contabo
role:        standby
region:      contabo
lifecycle:   {status: planned}
destination: {name: contabo-standby}
envs:        [prod]
stacks:      {include: [infrastructure, storage, databases, security, application, backup-dr]}
values:      {ref: values/contabo-standby/}
replication: {role: replica, source: onprem-primary}
EOF
cat > platform/clusters/azure-dr.yaml <<'EOF'
name:        azure-dr
provider:    azure
role:        dr
region:      centralindia
lifecycle:   {status: cold}
destination: {name: azure-dr}
envs:        [prod]
stacks:      {include: [databases, security, application, backup-dr]}
values:      {ref: values/azure-dr/}
replication: {role: replica, source: onprem-primary, mode: cold-restore-from-blob}
EOF
cat > platform/clusters/ovh-proving-ground.yaml <<'EOF'
name:        ovh-proving-ground
provider:    ovh
role:        proving-ground
region:      ap-south-1
lifecycle:   {status: active, decommission_by: "2026-11-30", purpose: "rehearse pn-platform bootstrap + failover before on-prem/contabo"}
destination: {name: ovh-proving-ground}
envs:        [staging]
stacks:      {include: all}
values:      {ref: values/ovh-proving-ground/}
replication: {role: none}
EOF
printf '# platform/clusters — the cluster REGISTRY (data)\n\nOne file per cluster. Schema + rationale: docs/design/directory-structure-and-cluster-registry.md\nThe stack-orchestrator (P1) stamps registry × stacks into Applications.\n' > platform/clusters/README.md
```
- [ ] **Step 2: Verify each parses as YAML**
```bash
for f in platform/clusters/*.yaml; do python3 -c "import yaml,sys; yaml.safe_load(open('$f')); print('$f OK')"; done
```
Expected: 4 `OK` lines.
- [ ] **Step 3: Commit**
```bash
git add platform/clusters
git -c user.email=snoorullah@proficientnow.com -c user.name="Shaik Noorullah" commit -q -m "feat(platform): add the cluster registry (4 clusters as data)"
```

### Task 6: Scaffold the `app-factory` library-chart stub

**Files:** Create `platform/app-factory/{Chart.yaml,README.md,.gitkeep-templates}` (P1 fills the templates)

- [ ] **Step 1: Create the library-chart skeleton**
```bash
mkdir -p platform/app-factory/templates
cat > platform/app-factory/Chart.yaml <<'EOF'
apiVersion: v2
name: app-factory
description: Library chart that stamps ArgoCD AppProjects + Applications with the enforced pn-platform taxonomy.
type: library
version: 0.0.0
EOF
printf '# app-factory (library chart)\n\nStamps every AppProject + Application with the enforced label/annotation taxonomy\n(docs/design/app-factory-label-taxonomy.md) and derives sync-wave from dependency-layer.\n\nSTATUS: skeleton — templates are implemented by the P1 plan.\n' > platform/app-factory/README.md
touch platform/app-factory/templates/.gitkeep
```
- [ ] **Step 2: Verify it lints as an (empty) library chart**
```bash
helm lint platform/app-factory 2>&1 | tail -2
```
Expected: no ERROR (library chart with no templates lints clean).
- [ ] **Step 3: Commit**
```bash
git add platform/app-factory
git -c user.email=snoorullah@proficientnow.com -c user.name="Shaik Noorullah" commit -q -m "feat(platform): scaffold app-factory library chart (stub for P1)"
```

### Task 7: Reserve `cli/` + fix `.gitignore`

**Files:** Create `cli/README.md`; Modify `.gitignore`

- [ ] **Step 1: Reserve cli/ + ignore generated artifacts**
```bash
mkdir -p cli
printf '# cli — the `pn` orchestrator (RESERVED)\n\nDesign deferred (see onprem-primary-platform-and-repo-plan). Scoped go.mod lives HERE, not repo-root.\n' > cli/README.md
for p in '.pi/' 'platform/bootstrap/.generated/' 'platform/bootstrap/secrets/' '**/charts/*.tgz'; do
  grep -qxF "$p" .gitignore 2>/dev/null || echo "$p" >> .gitignore
done
```
- [ ] **Step 2: Verify the generated dirs are now ignored**
```bash
git check-ignore platform/bootstrap/secrets/ .pi/ && echo "ignored ok"
git status --porcelain | grep -E '^\?\? (\.pi/|platform/bootstrap/secrets/)' && echo "STILL UNTRACKED — fix .gitignore" || echo "clean"
```
- [ ] **Step 3: Commit**
```bash
git add cli/README.md .gitignore
git -c user.email=snoorullah@proficientnow.com -c user.name="Shaik Noorullah" commit -q -m "chore: reserve cli/ + gitignore generated bootstrap artifacts"
```

### Task 8: Final tree + repo gate

**Files:** none (verification)

- [ ] **Step 1: Assert the target top-level shape**
```bash
for d in provisioner infrastructure platform application cli docs; do test -d "$d" && echo "$d ✓" || echo "$d MISSING"; done
for d in api config container-orchestration v0.2.0 business platform/tenant-clusters; do test ! -e "$d" && echo "$d removed ✓" || echo "$d STILL PRESENT"; done
test ! -f go.mod && echo "root go.mod removed ✓"
```
Expected: all `✓`.
- [ ] **Step 2: Repo lint gate** — no broken YAML/charts introduced
```bash
find platform/clusters -name '*.yaml' -exec python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" {} \; && echo "registry YAML clean"
helm lint platform/app-factory 2>&1 | grep -q 'no failures\|0 chart(s) failed' && echo "app-factory lints"
```
- [ ] **Step 3: Push all P0 commits**
```bash
git -c credential.helper='!gh auth git-credential' push https://github.com/ProficientnowTech/pn-platform.git HEAD:refs/heads/main
```
- [ ] **Step 4: Verify remote** — `git ls-remote origin refs/heads/main` matches local `HEAD`.

---

## Self-review
- **Spec coverage:** delete api-CLI ✓ (T2), speculative bits ✓ (T3), migrate business ✓ (T4), scaffold clusters ✓ (T5) / app-factory ✓ (T6) / cli ✓ (T7); old factory preserved (constraint). Gap: `platform/bootstrap` AKV→ESO seed is **P2/P3 scope**, not P0 — intentionally deferred.
- **Placeholders:** none — every scaffold has real content; registry files are complete data.
- **Consistency:** paths match the directory-structure design; registry fields match the taxonomy's `cluster`/`stacks` values.

---

## Execution notes (P0 done 2026-07-28)

Deviations from the plan as-written, discovered during execution:
- **Task 2 expanded (user-approved "A"):** the api-CLI monorepo was **not** cleanly isolated — `platform/run.sh` shelled into `container-orchestration/`, and 3 platform READMEs documented the `api→…→container-orchestration` flow. So the delete also removed **`platform/run.sh`** and repointed those 3 READMEs to the Talos+kapp+ArgoCD model. `infrastructure/deploy.sh` was verified **unaffected** (it calls the Proxmox templates/pools/nodes subdir `run.sh`, not `platform/run.sh`).
- **Task 4 needed a follow-up fix commit:** 4 files had stale `business/` paths (ArgoCD `source.path` + Tekton overlay paths) — repointed to `application/`. Tekton `pipelines/` were **moved** (not deleted) to `developer-platform/`; consolidation intent is to eventually replace them with Argo Workflows (deferred to the CI/CD-stack decision).
- **Task 5:** registry has **3 clusters** (onprem-primary, contabo-standby, azure-dr) — `ovh-proving-ground` dropped per the user's "remove OVH."
- **Added:** a scoped `git clean -fdx` of the deleted dirs' `.gitignore`'d leftovers (caches/outputs/inventories; no creds) so the working tree matches HEAD.

**FLAGGED — not done in P0 (need a decision):**
- The design doc (`directory-structure-and-cluster-registry.md` D5 + §line-102) also lists **`infrastructure/platforms/{baremetal,cloud}`** for deletion (old Packer/cloud stubs that reference the now-deleted API CLI) — the P0 plan omitted it.
- The broader **`infrastructure/`** old Proxmox-Packer provisioning (`deploy.sh` + `platforms/proxmox/terraform/{templates,pools,nodes}`) **overlaps with P3's new bpg/Talos approach** — a reconciliation to settle at P3 time, not P0.
- `README.md` (root) + `docs/{cni-architecture,multi-cluster-network-architecture}.md` still cite the deleted `./run.sh` — stale docs, not breaking.
