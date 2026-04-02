# PLAN-CICD-0001: Execution Plan for Argo Workflows CI/CD Architecture

| Field          | Value                                      |
|----------------|--------------------------------------------|
| Plan ID        | PLAN-CICD-0001                             |
| RFC            | RFC-CICD-0001                              |
| Status         | Draft                                      |
| Created        | 2026-03-30                                 |
| Last Updated   | 2026-03-30                                 |

---

## Overview

This plan breaks the implementation of RFC-CICD-0001 into six sequential phases
(A through F) with parallelizable tasks within each phase. Each phase has
explicit dependencies, a verification gate that must pass before proceeding,
and a rollback strategy.

### Repositories Involved

| Repo | Branch | Contents Affected |
|------|--------|-------------------|
| `pnow-ats-v2` | `feat/ci-dag-generator` (then PR to `develop`) | `nx.json`, `tools/ci/` scripts |
| `pn-infra-main` | `v2` | `platform/stacks/developer-platform/charts/argo-ci/` |

### Current State Summary

The argo-ci Helm chart already contains:

- **EventSource** (`github-webhook`) receiving pull_request and push events
- **Sensor** (`ci-trigger`) dispatching to `pr-validation` and `post-merge-build` WorkflowTemplates
- **WorkflowTemplates** using a shared CephFS PVC (`ci-workspace`, 20Gi, `ceph-filesystem`, RWX)
  -- will be replaced with RWO block PVC (`app-blk-hdd-repl`)
- **ExternalSecrets** for GitHub token, Harbor docker config, Slack webhook
- **RBAC** with `ci-workflow` ServiceAccount and ClusterRole
- **Vault Policy** granting read on `secret/data/ci/*`

The `pnow-ats-v2` repo contains:

- `tools/ci/generate-argo-dag.mjs` -- translates Nx task graph to Argo Workflow YAML
- `tools/ci/service-config.mjs` -- resolves Dockerfile, build-args, team per service
- `nx.json` -- no S3 remote cache configured yet

### What Must Change

1. Nx S3 remote cache replaces CephFS for build artifact sharing
2. CephFS PVC replaced with RWO block storage PVC (`app-blk-hdd-repl`) for workspace persistence
3. WorkflowTemplates rewritten to use ContainerSet + RWO PVC (with mutex) instead of CephFS PVC
4. Workflow git-sync steps clone/fetch directly from GitHub via HTTPS + PAT
5. Verdaccio publish step added for shared library distribution
6. DAG generator updated for file-based output and Nx cache env injection
7. `rewrite-workspace-refs.mjs` script created for workspace protocol resolution
8. Hardening controls (timeouts, Pod GC, semaphores, read-only cache for PRs)
9. Old CephFS PVC and Tekton resources removed

---

## Phase A: Foundation

**Dependencies:** None -- can start immediately.

**Goal:** All secrets and configuration exist in the cluster. Nx knows how to
use S3 remote cache. Nothing runs yet -- this is pure infrastructure prep.

### Tasks

All four tasks are independent and can execute in parallel.

#### A1: Nx Powerpack License Key

| Item | Value |
|------|-------|
| Repo | Cluster + Vault |
| Owner | Subagent `nx-config` |

**Steps:**

1. Generate `NX_KEY` (Nx Powerpack license key from the Nx dashboard).
2. Write the key to Vault at `secret/data/ci/nx`:
   ```
   vault kv put secret/ci/nx key=<NX_KEY_VALUE>
   ```
3. The existing Vault policy `eso-ci-secrets-policy` already grants read on
   `secret/data/ci/*`, so no policy change is needed.
4. Add an ExternalSecret entry to the argo-ci chart values.yaml:
   ```yaml
   nxKey:
     enabled: true
     refreshInterval: 1h
     target: nx-key
     data:
       - secretKey: key
         remoteRef:
           key: ci/nx
           property: key
   ```
5. The existing `externalsecrets.yaml` template will render this automatically
   (it iterates `.Values.secrets`).

**Artifacts produced:**
- Vault path `secret/data/ci/nx` populated
- K8s Secret `nx-key` in `argo` namespace (via ExternalSecret)

#### A2: ObjectBucketClaim for Nx S3 Cache

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` (argo-ci chart) |
| Owner | Subagent `infra-secrets` |

**Steps:**

1. Create an ObjectBucketClaim (OBC) manifest in the argo-ci chart templates:
   ```yaml
   # templates/obc-nx-cache.yaml
   apiVersion: objectbucket.io/v1alpha1
   kind: ObjectBucketClaim
   metadata:
     name: nx-cache
   spec:
     generateBucketName: nx-cache
     storageClassName: ceph-bucket
   ```
   The Rook-Ceph operator will provision the bucket and create two K8s resources:
   - ConfigMap `nx-cache` (contains `BUCKET_HOST`, `BUCKET_PORT`, `BUCKET_NAME`)
   - Secret `nx-cache` (contains `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)

2. No ExternalSecret needed for S3 credentials -- OBC produces them directly as
   a K8s Secret. The workflow templates will reference this Secret by name.

**Artifacts produced:**
- OBC `nx-cache` in `argo` namespace
- Auto-generated ConfigMap `nx-cache` with endpoint info
- Auto-generated Secret `nx-cache` with S3 credentials

#### A3: Verdaccio Token

| Item | Value |
|------|-------|
| Repo | Vault + `pn-infra-main` (argo-ci chart) |
| Owner | Subagent `infra-secrets` |

**Steps:**

1. Generate an auth token from the in-cluster Verdaccio instance:
   ```
   curl -XPUT -H "Content-Type: application/json" \
     -d '{"name":"ci-publisher","password":"<generated>"}' \
     http://verdaccio.verdaccio.svc:4873/-/user/org.couchdb.user:ci-publisher
   ```
   Extract the token from the response.

2. Write the token to Vault:
   ```
   vault kv put secret/ci/verdaccio token=<TOKEN> registry=http://verdaccio.verdaccio.svc:4873
   ```

3. Add ExternalSecret entries to argo-ci `values.yaml`:
   ```yaml
   verdaccioToken:
     enabled: true
     refreshInterval: 1h
     target: verdaccio-token
     data:
       - secretKey: token
         remoteRef:
           key: ci/verdaccio
           property: token
       - secretKey: registry
         remoteRef:
           key: ci/verdaccio
           property: registry
   ```

**Artifacts produced:**
- Vault path `secret/data/ci/verdaccio` populated
- K8s Secret `verdaccio-token` in `argo` namespace

#### A4: Nx S3 Remote Cache Configuration

| Item | Value |
|------|-------|
| Repo | `pnow-ats-v2` |
| Owner | Subagent `nx-config` |

**Steps:**

1. Add the `remoteCache` block to `nx.json`:
   ```json
   {
     "remoteCache": {
       "provider": "s3",
       "options": {
         "endpoint": "${NX_CACHE_S3_ENDPOINT}",
         "bucket": "${NX_CACHE_S3_BUCKET}",
         "region": "us-east-1",
         "forcePathStyle": true,
         "disableChecksum": true
       }
     }
   }
   ```
   The actual values (`endpoint`, `bucket`) are injected via environment
   variables at runtime. `forcePathStyle` is required because Ceph RGW does
   not support virtual-hosted-style. `disableChecksum` avoids checksum
   validation overhead on the Ceph S3 gateway.

2. The `NX_KEY`, `NX_CACHE_S3_ENDPOINT`, `NX_CACHE_S3_BUCKET`,
   `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` env vars will be set
   in the workflow templates (Phase B), not in nx.json.

**Artifacts produced:**
- Updated `nx.json` with `remoteCache` block committed to `pnow-ats-v2`

### Verification Gate

All of the following must be true before proceeding to Phase B:

| Check | Command / Method | Expected Result |
|-------|-----------------|-----------------|
| Nx key synced | `kubectl get externalsecret nx-key -n argo` | `SecretSynced` |
| OBC provisioned | `kubectl get obc nx-cache -n argo` | `Bound` |
| OBC ConfigMap exists | `kubectl get cm nx-cache -n argo` | Has `BUCKET_HOST`, `BUCKET_PORT`, `BUCKET_NAME` |
| OBC Secret exists | `kubectl get secret nx-cache -n argo` | Has `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| Verdaccio token synced | `kubectl get externalsecret verdaccio-token -n argo` | `SecretSynced` |
| nx.json updated | `cat pnow-ats-v2/nx.json \| jq .remoteCache` | Contains S3 provider config |

### Rollback

- **Vault secrets:** `vault kv delete secret/ci/nx` and `vault kv delete secret/ci/verdaccio`
- **OBC:** Delete the OBC manifest from the chart, ArgoCD removes the OBC and bucket
- **ExternalSecrets:** Remove entries from `values.yaml`, ArgoCD removes the ExternalSecrets
- **nx.json:** `git revert` the commit that added `remoteCache`

---

## Phase B: Workflow Rewrite

**Dependencies:** Phase A complete (all secrets synced, nx.json committed).

**Goal:** Rewrite both WorkflowTemplates to use ContainerSet + RWO block PVC
(with mutex for serialized access), configure git-sync steps to clone/fetch
directly from GitHub via HTTPS + PAT, inject Nx cache env vars, and create
the supporting scripts.

### Tasks

B1 and B2 are independent rewrites of different templates. B3 and B4 are
independent script tasks. All four can execute in parallel.

#### B1: Rewrite `pr-validation` WorkflowTemplate

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| File | `argo-ci/templates/workflow-pr-validation.yaml` |
| Owner | Subagent `workflow-templates` |

**Key changes from current template:**

1. **Replace CephFS PVC with RWO block PVC.** Change the `ci-workspace` PVC
   StorageClass from `ceph-filesystem` to `app-blk-hdd-repl` (RWO block storage).
   Keep the `synchronization.mutex` to serialize access to the PVC.

2. **Replace sequential container steps with ContainerSet.** The `validate`
   entrypoint becomes a `containerSet` template with containers sharing the
   RWO PVC volume at `/workspace`. The PVC retains the git clone, pnpm store,
   and Nx local cache between runs for warm-start performance.

2a. **Configure git-sync to clone/fetch from GitHub.** The `git-clone`
   container fetches directly from GitHub via HTTPS using the PAT from the
   `github-token` Secret. On a warm PVC (existing clone), it runs `git fetch` +
   `git checkout` (seconds, only delta refs). On a cold PVC, it runs a full
   `git clone` from GitHub.

3. **Inject Nx S3 cache env vars** into the `generate-task-dag` and `nx-task`
   containers:
   ```yaml
   env:
     - name: NX_KEY
       valueFrom:
         secretKeyRef:
           name: nx-key
           key: key
     - name: AWS_ACCESS_KEY_ID
       valueFrom:
         secretKeyRef:
           name: nx-cache
           key: AWS_ACCESS_KEY_ID
     - name: AWS_SECRET_ACCESS_KEY
       valueFrom:
         secretKeyRef:
           name: nx-cache
           key: AWS_SECRET_ACCESS_KEY
     - name: NX_CACHE_S3_ENDPOINT
       valueFrom:
         configMapKeyRef:
           name: nx-cache
           key: BUCKET_HOST
     - name: NX_CACHE_S3_BUCKET
       valueFrom:
         configMapKeyRef:
           name: nx-cache
           key: BUCKET_NAME
   ```

4. **Set `NX_POWERPACK_CACHE_MODE=read-only`** for PR workflows. PRs should
   read from cache but never populate it (avoids poisoning from untrusted
   branches). This is added in Phase E (E4) but the env var placeholder
   should be present now.

5. **Upload workspace as S3 artifact** after the ContainerSet completes, for
   kaniko fan-out pods to download into emptyDir. The tar excludes `.git`,
   pnpm store, and Nx local cache (those persist on the PVC). Uses Argo's
   built-in S3 artifact support with a key path including `{{workflow.name}}`
   to avoid collisions.

6. **Keep the `synchronization.mutex`** (`ci-workspace`) -- the RWO PVC
   requires serialized access. The mutex ensures only one workflow mounts the
   PVC at a time.

**Artifacts produced:**
- Rewritten `workflow-pr-validation.yaml` in the argo-ci chart

#### B2: Rewrite `post-merge-build` WorkflowTemplate

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| File | `argo-ci/templates/workflow-post-merge-build.yaml` |
| Owner | Subagent `workflow-templates` |

**Key changes from current template:**

1. **Same RWO block PVC + ContainerSet pattern** as B1. Git-sync fetches
   directly from GitHub via HTTPS + PAT. PVC retains workspace data between runs.

2. **Keep mutex** -- same as B1. RWO PVC requires serialized access.

3. **Add Verdaccio publish step** using the `publish-to-verdaccio` template:
   ```yaml
   - name: publish-to-verdaccio
     container:
       image: {{ .Values.ciImage }}
       command: [sh, -c]
       args:
         - |
           cd /workspace
           node tools/ci/rewrite-workspace-refs.mjs
           echo "//$(VERDACCIO_REGISTRY#http://)/:_authToken=${VERDACCIO_TOKEN}" > .npmrc
           npx nx release publish --yes --registry=${VERDACCIO_REGISTRY}
       env:
         - name: VERDACCIO_TOKEN
           valueFrom:
             secretKeyRef:
               name: verdaccio-token
               key: token
         - name: VERDACCIO_REGISTRY
           valueFrom:
             secretKeyRef:
               name: verdaccio-token
               key: registry
   ```
   This replaces the current `npm-publish` template which has no registry
   targeting or workspace ref rewriting.

4. **Kaniko S3 artifact download** -- each kaniko-build task downloads the
   workspace artifact from S3 into an emptyDir. This decouples kaniko builds
   from the RWO PVC (which is mutex-locked to the ContainerSet).

5. **Inject Nx S3 cache env vars** into all relevant containers (same as B1,
   but without the read-only restriction).

6. **Update kaniko-build template** -- add `--build-arg=VERDACCIO_REGISTRY`
   to allow Dockerfiles to install shared libs from in-cluster Verdaccio.

**Artifacts produced:**
- Rewritten `workflow-post-merge-build.yaml` in the argo-ci chart

#### B3: Create `rewrite-workspace-refs.mjs`

| Item | Value |
|------|-------|
| Repo | `pnow-ats-v2` |
| File | `tools/ci/rewrite-workspace-refs.mjs` |
| Owner | Subagent `ci-scripts` |

**Purpose:** Before publishing to Verdaccio, workspace protocol references
(`"workspace:*"`, `"workspace:^"`) in `package.json` files must be resolved
to concrete semver versions. pnpm publish handles this for pnpm, but
`nx release publish` does not always do it correctly for all package managers.

**Steps:**

1. Iterate all `packages/*/package.json` (shared libs in the monorepo).
2. For each `dependencies` and `peerDependencies` entry matching `workspace:*`:
   - Look up the referenced package's `package.json` to get its `version` field.
   - Replace `"workspace:*"` with the concrete version (e.g., `"1.2.3"`).
   - Replace `"workspace:^"` with `"^1.2.3"`.
   - Replace `"workspace:~"` with `"~1.2.3"`.
3. Write the modified `package.json` files in place (these are in the emptyDir
   workspace, not the git tree).
4. Add unit tests in `rewrite-workspace-refs.test.mjs`.

**Artifacts produced:**
- `tools/ci/rewrite-workspace-refs.mjs`
- `tools/ci/rewrite-workspace-refs.test.mjs`

#### B4: Fix `generate-argo-dag.mjs`

| Item | Value |
|------|-------|
| Repo | `pnow-ats-v2` |
| File | `tools/ci/generate-argo-dag.mjs` |
| Owner | Subagent `ci-scripts` (shared with `nx-config`) |

**Current issues:**

1. The `generateWorkflowYaml` function generates a child workflow that
   references the PVC (`ci-workspace`). The child workflow (for PR validation)
   uses an S3 artifact input with emptyDir for task execution; the parent
   ContainerSet uses the RWO PVC directly.

2. The child workflow's `nx-task` template does not have Nx S3 cache env vars
   injected. Without these, tasks in the child workflow cannot read/write the
   remote cache.

3. The function writes directly to `/tmp/` paths. The output should be
   configurable for testability.

**Changes:**

1. Update `generateWorkflowYaml`:
   - Child workflow tasks use emptyDir with S3 artifact input (downloaded
     workspace tar from the parent ContainerSet).
   - Inject `NX_KEY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
     `NX_CACHE_S3_ENDPOINT`, `NX_CACHE_S3_BUCKET` env vars into the
     `nx-task` container template via `envFrom` referencing the Secrets
     and ConfigMaps.

2. Accept an optional `OUTPUT_DIR` env var (defaults to `/tmp`) for output
   paths. This makes unit tests deterministic.

3. Update existing tests in `generate-argo-dag.test.mjs` to verify:
   - emptyDir volume in child workflow output YAML (child tasks)
   - Nx env vars present in nx-task container
   - Parent ContainerSet references the RWO PVC (not emptyDir)

**Artifacts produced:**
- Updated `tools/ci/generate-argo-dag.mjs`
- Updated `tools/ci/generate-argo-dag.test.mjs`

### Verification Gate

All of the following must be true before proceeding to Phase C:

| Check | Command / Method | Expected Result |
|-------|-----------------|-----------------|
| PR validation template renders | `helm template argo-ci . \| yq '.kind == "WorkflowTemplate"'` | No errors, valid YAML |
| Post-merge template renders | Same as above | No errors, valid YAML |
| RWO PVC referenced (not CephFS) | `helm template argo-ci . \| grep "app-blk-hdd-repl"` | Found in PVC template |
| No CephFS references | `grep -r "ceph-filesystem" templates/` | No matches |
| Mutex present | `helm template argo-ci . \| grep "ci-workspace"` | Found in synchronization.mutex |
| GitHub URL in git-clone | `helm template argo-ci . \| grep "github.com"` | Found in both templates |
| Nx env vars present | `helm template argo-ci . \| grep "NX_KEY"` | Found |
| rewrite-workspace-refs tests pass | `cd pnow-ats-v2 && npx jest tools/ci/rewrite-workspace-refs.test.mjs` | All pass |
| generate-argo-dag tests pass | `cd pnow-ats-v2 && npx jest tools/ci/generate-argo-dag.test.mjs` | All pass |
| Child workflow uses emptyDir + S3 | Inspect `generateWorkflowYaml` output in test | emptyDir for child tasks, S3 artifact input |

### Rollback

- **WorkflowTemplates:** `git revert` the commit(s) on `pn-infra-main`. ArgoCD
  auto-syncs the previous template versions within its sync interval.
- **Scripts:** `git revert` the commit(s) on `pnow-ats-v2`. Scripts are only
  executed at CI runtime, so reverting the source is sufficient.

---

## Phase C: Deploy and Test PR Validation

**Dependencies:** Phase B complete (templates render, scripts pass tests).

**Goal:** Deploy the updated argo-ci chart and verify the PR validation workflow
runs to `Succeeded` on a real GitHub pull request.

### Tasks

These tasks are strictly sequential -- each depends on the output of the
previous step.

#### C1: Deploy Updated argo-ci Chart

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Subagent `verification` |

**Steps:**

1. Create a PR on `pn-infra-main` targeting `v2` with all Phase A and Phase B
   changes to the argo-ci chart.
2. Review the PR diff to confirm:
   - New OBC manifest
   - New ExternalSecret values for `nxKey` and `verdaccioToken`
   - Rewritten `workflow-pr-validation.yaml`
   - Rewritten `workflow-post-merge-build.yaml`
   - No accidental changes to other charts
3. Merge the PR.
4. Wait for ArgoCD to sync the `argo-ci` Application. Verify sync status:
   ```
   argocd app get developer-platform --grpc-web
   ```
5. Confirm all new resources are healthy:
   ```
   kubectl get obc,externalsecret,workflowtemplate -n argo
   ```

#### C2: Trigger PR Validation

| Item | Value |
|------|-------|
| Repo | `pnow-ats-v2` |
| Owner | Subagent `verification` |

**Steps:**

1. Ensure the `tools/ci/` changes and `nx.json` changes from Phase A4/B3/B4
   are merged to `develop` in `pnow-ats-v2`.
2. Create a test branch from `develop`.
3. Make a trivial change (e.g., add a comment to `apps/backend/mailer/src/main.ts`).
4. Push the branch and open a PR against `develop`.
5. The GitHub webhook fires, Argo Events receives it, and the Sensor triggers
   the `pr-validation` WorkflowTemplate.

#### C3: Watch Workflow to Succeeded

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. Watch the workflow in the Argo UI or via CLI:
   ```
   argo watch -n argo @latest
   ```
2. Observe each step completing:
   - `report-pending` -- GitHub status set to pending
   - `git-sync` -- repo fetched/cloned from GitHub into RWO PVC
   - `install` -- `pnpm install` completes (using cached store on PVC)
   - `generate-dag` -- DAG YAML generated, affected-apps JSON written
   - `run-tasks` -- child workflow submitted and completed
   - `report-success` -- GitHub status set to success
3. The workflow MUST reach `Succeeded` status. `Running` is not acceptable.
4. Verify the `git-sync` step logs show the GitHub URL
   (`github.com`), confirming direct fetch via HTTPS + PAT.

**Diagnostic framework if workflow fails:**

1. Check `argo get -n argo <workflow-name>` for step-level status.
2. Check `argo logs -n argo <workflow-name>` for container logs.
3. Check `kubectl get events -n argo --sort-by=.lastTimestamp` for pod scheduling issues.
4. Check `kubectl describe pod -n argo <pod-name>` for volume mount or secret injection failures.
5. Common failure modes:
   - Secret not found: ExternalSecret not synced -- check Phase A verification gate
   - OBC ConfigMap missing: Rook operator not reconciled -- check `kubectl get obc -n argo`
   - Child workflow stuck: RBAC insufficient -- check `ci-workflow` ClusterRole
   - Node.js OOM: Increase memory limits in `generate-task-dag` template

#### C4: Verify GitHub Commit Status

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. Check the PR on GitHub -- the commit status should show `argo-ci/validation`
   with a green checkmark.
2. Alternatively verify via API:
   ```
   gh api repos/snoorullah/pnow-ats-v2/commits/<SHA>/statuses | jq '.[0]'
   ```
3. Expected: `state: "success"`, `context: "argo-ci/validation"`.

#### C5: Verify Nx S3 Cache Entries

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. Get the bucket name from the OBC ConfigMap:
   ```
   BUCKET=$(kubectl get cm nx-cache -n argo -o jsonpath='{.data.BUCKET_NAME}')
   ```
2. List objects in the bucket (using the RGW endpoint):
   ```
   aws s3 ls s3://${BUCKET}/ --endpoint-url http://<rgw-endpoint>
   ```
3. Confirm cache entries exist (hashed task output directories).

**Note:** If `NX_POWERPACK_CACHE_MODE=read-only` was already set for PRs
(Phase E4 done early), the cache will NOT have entries from this PR run.
In that case, verify the cache is populated by a post-merge run in Phase D.

### Verification Gate

All of the following must be true before proceeding to Phase D:

| Check | Expected Result |
|-------|-----------------|
| Workflow status | `Succeeded` (not `Running`, not `Failed`) |
| GitHub commit status | `success` for context `argo-ci/validation` |
| Git-sync used GitHub URL | Workflow logs show `github.com` for the git clone/fetch step |
| RWO PVC in use (not CephFS) | `kubectl get pvc ci-workspace -n argo -o jsonpath='{.spec.storageClassName}'` returns `app-blk-hdd-repl` |
| S3 cache entries exist | Bucket is non-empty (unless read-only mode active) |
| All child workflow tasks completed | `argo get -n argo <child-workflow>` shows all DAG tasks Succeeded |

### Rollback

If the PR validation workflow fails and cannot be fixed within a reasonable
time window:

1. Revert the argo-ci chart changes on `pn-infra-main:v2`.
2. ArgoCD auto-syncs the old WorkflowTemplates.
3. The old PVC-based templates resume operation.
4. Investigate the failure using the diagnostic framework above.

---

## Phase D: Test Post-Merge Build

**Dependencies:** Phase C complete (PR validation Succeeded).

**Goal:** Verify the full post-merge pipeline: build, Verdaccio publish, Docker
image push, GitOps update, and ArgoCD deployment.

### Tasks

These tasks are strictly sequential.

#### D1: Make a Real Service Change

| Item | Value |
|------|-------|
| Repo | `pnow-ats-v2` |
| Owner | Subagent `verification` |

**Steps:**

1. Create a branch from `develop`.
2. Make a small but real change to a service, e.g., add a log statement to
   `apps/backend/mailer/src/main.ts`:
   ```typescript
   // CI pipeline verification: post-merge build test
   ```
3. This ensures `nx affected` detects the mailer service as changed.

#### D2: Create PR and Merge to develop

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. Push the branch, open a PR against `develop`.
2. Wait for PR validation to pass (Phase C already verified this works).
3. Merge the PR. This triggers the `pr-merged-develop` sensor dependency.

#### D3: Watch Post-Merge Workflow to Succeeded

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. The sensor submits a `post-merge-build` workflow with `generateName: build-staging-`.
2. Watch the workflow:
   ```
   argo watch -n argo @latest
   ```
3. Observe each step completing:
   - `git-sync` -- repo fetched from GitHub into RWO PVC
   - `install` -- `pnpm install` completes (cached store on PVC)
   - `generate-dag` -- DAG generated for `build` target only
   - `run-tasks` -- child workflow runs build tasks
   - `publish-packages` -- shared libs published to Verdaccio
   - `docker-builds` -- Kaniko fan-out builds Docker images (S3 artifact into emptyDir)
   - `update-gitops` -- image tags committed to `pn-infra-main:v2`
   - `notify` -- Slack notification sent
4. The workflow MUST reach `Succeeded`.

**Diagnostic framework if workflow fails:**

Same as Phase C, plus:

- **Verdaccio publish fails:** Check `verdaccio-token` secret exists, check
  `rewrite-workspace-refs.mjs` ran correctly, check Verdaccio pod logs.
- **Kaniko build fails:** Check `harbor-docker-config` secret mounted, check
  Kaniko executor logs, check S3 artifact download into emptyDir succeeded.
- **GitOps update fails:** Check GitHub token has push access to `pn-infra`,
  check `pn-infra:v2` branch exists, check for merge conflicts.

#### D4: Verify Shared Libs Published to Verdaccio

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. If any shared libraries were affected by the change, verify they were
   published:
   ```
   curl -s http://verdaccio.verdaccio.svc:4873/-/verdaccio/packages | jq '.[] | select(.name | startswith("@pnats"))'
   ```
2. If no shared libs were affected (only `mailer` changed), this step is a
   no-op -- confirm the publish step was skipped or ran as no-op.

#### D5: Verify Docker Image in Harbor

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. Check Harbor for the newly pushed image:
   ```
   curl -s -u admin:$HARBOR_PASSWORD \
     "https://registry.pnats.cloud/api/v2.0/projects/pnats/repositories/mailer/artifacts" \
     | jq '.[0].tags'
   ```
2. Verify the image tag matches the merge commit SHA.
3. Verify the `latest` tag was also updated.

#### D6: Verify GitOps Update in pn-infra

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. Check the latest commit on `pn-infra-main:v2`:
   ```
   cd /home/devsupreme/work/pn-infra-main && git pull origin v2
   git log -1 --oneline
   ```
2. The commit message should be:
   `chore(deploy): update image tags to <merge-commit-sha>`
3. Verify the affected service's Helm values file has the new tag:
   ```
   grep "tag:" <service-values-path>
   ```

#### D7: Verify ArgoCD Deployment

| Item | Value |
|------|-------|
| Owner | Subagent `verification` |

**Steps:**

1. Wait for ArgoCD to detect the new commit and sync:
   ```
   argocd app get <service-app-name> --grpc-web
   ```
2. Verify the app is `Synced` and `Healthy`.
3. Verify the running pod has the new image tag:
   ```
   kubectl get pod -n <namespace> -l app=mailer -o jsonpath='{.items[0].spec.containers[0].image}'
   ```
4. Expected: `registry.pnats.cloud/pnats/mailer:<merge-commit-sha>`

### Verification Gate

All of the following must be true before proceeding to Phase E:

| Check | Expected Result |
|-------|-----------------|
| Post-merge workflow status | `Succeeded` |
| Docker image in Harbor | Tag matches merge commit SHA |
| GitOps commit in pn-infra | Image tag updated in values file |
| ArgoCD sync status | `Synced` + `Healthy` |
| Running pod image | Matches new tag |
| Slack notification received | Build success message in CI channel |

### Rollback

- **No production impact.** The post-merge build targets `develop` (staging).
  If it fails, no images are pushed, no gitops commits are made, and the
  existing deployment continues running the previous version.
- **To retry:** Fix the issue, push another commit to `develop`, and let the
  pipeline run again.
- **If Verdaccio has bad packages:** Unpublish the affected version:
  `npm unpublish @pnats/<pkg>@<version> --registry http://verdaccio...`

---

## Phase E: Hardening

**Dependencies:** Phase D complete (full post-merge pipeline verified).

**Goal:** Add operational guardrails -- timeouts, garbage collection, concurrency
controls, and read-only cache for PR workflows. Verify that Nx caching delivers
measurable speedup.

### Tasks

E1 through E4 are independent and can execute in parallel. E5 depends on all
others being deployed.

#### E1: Set activeDeadlineSeconds on All Workflow Templates

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Subagent `hardening` |

**Steps:**

1. Add `activeDeadlineSeconds` to each WorkflowTemplate spec:
   - `pr-validation`: 1800 (30 minutes)
   - `post-merge-build`: 3600 (60 minutes)
2. These are safety limits to prevent runaway workflows from consuming cluster
   resources indefinitely.

**Location:** `spec.activeDeadlineSeconds` in each WorkflowTemplate manifest.

#### E2: Configure Pod GC in Argo Workflows Helm Values

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Subagent `hardening` |

**Steps:**

1. Add Pod GC strategy to the argo-workflows Helm values (not the argo-ci
   chart -- this is the Argo Workflows controller configuration):
   ```yaml
   controller:
     podGCGracePeriodSeconds: 300
     podGCStrategy: OnWorkflowCompletion
   ```
2. Also add workflow-level Pod GC in both WorkflowTemplates:
   ```yaml
   spec:
     podGC:
       strategy: OnWorkflowSuccess
       deleteDelayDuration: 5m
   ```
   This keeps pods around for 5 minutes after success (for log inspection)
   but cleans them up automatically. Failed workflow pods are preserved for
   debugging.

#### E3: Add Semaphore ConfigMap for Child Workflow Concurrency

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Subagent `hardening` |

**Steps:**

1. Create a ConfigMap for semaphore-based concurrency control:
   ```yaml
   # templates/configmap-semaphore.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: ci-semaphore
   data:
     pr-validation: "3"
     post-merge-build: "2"
   ```
2. Update WorkflowTemplates to use semaphore instead of (the now-removed) mutex:
   ```yaml
   spec:
     synchronization:
       semaphore:
         configMapKeyRef:
           name: ci-semaphore
           key: pr-validation
   ```
3. This allows up to 3 concurrent PR validations and 2 concurrent post-merge
   builds, preventing resource exhaustion while allowing parallelism.

#### E4: Set Read-Only Cache for PR Workflows

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Subagent `hardening` |

**Steps:**

1. Add `NX_POWERPACK_CACHE_MODE=read-only` to env vars in the `pr-validation`
   WorkflowTemplate (in the `nx-task` container and `generate-task-dag`
   container).
2. This prevents untrusted PR branches from writing to the shared Nx cache.
   Only post-merge builds (from trusted branches) populate the cache.

#### E5: Verify Cache Hits on Second PR Run

| Item | Value |
|------|-------|
| Repo | `pnow-ats-v2` |
| Owner | Subagent `hardening` |

**Steps:**

1. First, ensure the post-merge build from Phase D has populated the Nx cache.
2. Create a new PR with a trivial change to the same service (mailer).
3. Run the PR validation workflow.
4. Observe Nx output logs -- tasks that were already cached should show
   `[remote cache]` in the output.
5. Compare the total workflow duration between:
   - Phase C (first run, cold cache): record duration
   - Phase E5 (second run, warm cache): record duration
6. The second run MUST be measurably faster. Expected speedup: 30-60% for
   cached targets.

### Verification Gate

All of the following must be true before proceeding to Phase F:

| Check | Expected Result |
|-------|-----------------|
| activeDeadlineSeconds set | Both templates have deadline |
| Pod GC configured | `kubectl get configmap -n argo workflow-controller-configmap -o yaml \| grep podGC` |
| Semaphore ConfigMap exists | `kubectl get cm ci-semaphore -n argo` |
| PR cache mode is read-only | Template has `NX_POWERPACK_CACHE_MODE=read-only` |
| Second PR run faster | Duration comparison shows measurable improvement |
| Nx cache hits in logs | `[remote cache]` appears in task output |

### Rollback

- **Hardening changes are additive** -- they add safety limits, not new
  functionality. Each can be reverted independently by removing the specific
  configuration.
- `activeDeadlineSeconds`: Remove the field to restore no-timeout behavior.
- Pod GC: Remove the `podGC` stanza; pods will accumulate but nothing breaks.
- Semaphore: Remove the ConfigMap and `synchronization` stanza; unlimited
  concurrency resumes.
- Read-only cache: Remove the env var; PRs will write to cache (less secure
  but functional).

---

## Phase F: Cleanup

**Dependencies:** Phase E complete (all hardening verified).

**Goal:** Remove legacy infrastructure that is no longer needed.

### Tasks

F1 and F2 can execute in parallel. F3 and F4 can execute in parallel after
F1/F2 are merged.

#### F1: Confirm CephFS PVC Fully Replaced

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Any subagent |

**Steps:**

1. Verify the `ci-workspace` PVC is using `app-blk-hdd-repl` StorageClass
   (already changed in Phase B, Step 11).
2. Verify no remaining references to `ceph-filesystem` in the argo-ci chart.
3. If the old CephFS PVC still exists as an orphan (different name), delete it:
   ```
   kubectl delete pvc <old-cephfs-pvc-name> -n argo
   ```
4. Confirm the `values.yaml` workspace section reflects:
   ```yaml
   workspace:
     storageClassName: app-blk-hdd-repl
     size: 20Gi
     accessMode: ReadWriteOnce
   ```

#### F2: Remove Old Tekton Resources

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Any subagent |

**Steps:**

1. Evaluate the Tekton chart at:
   `platform/stacks/development-workloads/charts/tekton/`
   - `templates/tektondashboard.yaml`
   - `templates/tektonconfig.yaml`
2. Determine if any non-CI workloads still depend on Tekton. If not:
   - Remove the entire `tekton/` chart directory.
   - Remove the Tekton Application reference from the stack orchestrator.
3. If other workloads depend on Tekton:
   - Remove only the CI-specific pipelines and tasks (if any exist outside
     the chart).
   - Leave the Tekton operator config intact.
4. Verify no orphaned Tekton PipelineRuns or TaskRuns remain:
   ```
   kubectl get pipelineruns,taskruns --all-namespaces
   ```

#### F3: Update RFC Cross-References

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Any subagent |

**Steps:**

1. If an RFC-PLATFORM-0001 exists, update it to reference RFC-CICD-0001 as
   the authoritative CI/CD architecture document.
2. Update the RFC-CICD-0001 index (`00-index.md`) status from `Draft` to
   `Implemented`.

#### F4: Update Engineering Platform Spec

| Item | Value |
|------|-------|
| Repo | `pn-infra-main` |
| Owner | Any subagent |

**Steps:**

1. Locate the engineering platform specification document (if it exists in
   `docs/platform/`).
2. Update the CI/CD section to reflect:
   - Argo Workflows as the CI engine (replacing Tekton)
   - S3-backed Nx remote cache (replacing CephFS)
   - ContainerSet + emptyDir workspace model
   - Verdaccio for shared library distribution
3. Remove any references to Tekton pipelines or CephFS-based CI.

### Verification Gate (Final)

| Check | Expected Result |
|-------|-----------------|
| No CephFS PVC in argo namespace | `kubectl get pvc ci-workspace -n argo -o jsonpath='{.spec.storageClassName}'` -- returns `app-blk-hdd-repl`, not `ceph-filesystem` |
| Tekton resources removed (if applicable) | No Tekton chart in development-workloads stack |
| RFC status updated | `00-index.md` shows `Implemented` |
| All workflows still pass | Run one more PR validation after cleanup |

### Rollback

- **PVC StorageClass revert:** Restore `ceph-filesystem` in `values.yaml`
  workspace block. Delete the RWO PVC and let ArgoCD recreate it with CephFS.
  Data on the PVC is transient and recoverable via re-clone.
- **Tekton removal:** Restore the chart directory from git history.

---

## Global Rollback Strategy

If at any phase the system is in a broken state that cannot be resolved:

| Phase | Rollback Method | Impact |
|-------|----------------|--------|
| **A** | Delete Vault secrets, revert `nx.json`, delete OBC manifest | No functional impact -- nothing was using the new secrets yet |
| **B** | `git revert` WorkflowTemplate changes on `pn-infra:v2`, revert PVC StorageClass to CephFS | ArgoCD auto-syncs old templates within sync interval; old CephFS-based pipeline resumes |
| **C** | Same as B -- revert to old templates | PR validation reverts to PVC-based flow |
| **D** | No rollback needed -- failure means no images were pushed | Existing staging deployment continues running previous version |
| **E** | Remove individual hardening settings | Pipeline continues without guardrails (functionally identical to Phase D state) |
| **F** | Restore deleted files from git history | PVC and Tekton resources recreated by ArgoCD |

**Critical safety property:** At no point during this plan is the production
deployment path broken. Post-merge builds to `main` are not tested until
Phase D is complete on `develop`. If the `develop` pipeline fails, `main`
is unaffected.

---

## Subagent Assignment Matrix

When executing via the Engineering Execution Framework Phase 5, tasks are
distributed across subagents to maximize parallelism while respecting repo
boundaries.

| Subagent | Repo | Tasks | Skills Required |
|----------|------|-------|-----------------|
| `nx-config` | `pnow-ats-v2` | A1, A4, B4 | Nx configuration, Node.js, S3 cache setup |
| `infra-secrets` | `pn-infra-main` | A2, A3 | Vault, ExternalSecrets, OBC, Helm |
| `workflow-templates` | `pn-infra-main` | B1, B2 | Argo Workflows, Helm templates, ContainerSet |
| `ci-scripts` | `pnow-ats-v2` | B3, B4 | Node.js, pnpm, workspace protocol |
| `verification` | Both repos + cluster | C1-C5, D1-D7 | kubectl, argo CLI, gh CLI, Harbor API |
| `hardening` | `pn-infra-main` | E1-E5 | Argo Workflows config, Nx cache modes |

### Parallelism Map

```
Phase A:  [A1] [A2] [A3] [A4]  ← all parallel
              │
Phase B:  [B1] [B2] [B3] [B4]     ← all parallel
              │
Phase C:  C1 → C2 → C3 → C4 → C5  ← sequential
              │
Phase D:  D1 → D2 → D3 → D4 → D5 → D6 → D7  ← sequential
              │
Phase E:  [E1] [E2] [E3] [E4]     ← parallel, then E5 sequential
              │
Phase F:  [F1] [F2] then [F3] [F4] ← two waves
```

### Estimated Timeline

| Phase | Duration (optimistic) | Duration (pessimistic) | Blocker Risk |
|-------|----------------------|----------------------|-------------|
| A | 1 hour | 4 hours | OBC provisioning delay, Nx license procurement |
| B | 4 hours | 8 hours | ContainerSet YAML complexity, test coverage |
| C | 1 hour | 4 hours | Webhook delivery, RBAC issues, secret injection |
| D | 2 hours | 6 hours | Kaniko build failures, GitOps push conflicts |
| E | 2 hours | 4 hours | Cache mode configuration, semaphore tuning |
| F | 1 hour | 2 hours | Tekton dependency audit |
| **Total** | **11 hours** | **28 hours** | |

---

## Appendix: Files Modified Summary

### pnow-ats-v2

| File | Phase | Action |
|------|-------|--------|
| `nx.json` | A4 | Add `remoteCache` block |
| `tools/ci/generate-argo-dag.mjs` | B4 | Replace PVC with emptyDir, add Nx env vars |
| `tools/ci/generate-argo-dag.test.mjs` | B4 | Update tests |
| `tools/ci/rewrite-workspace-refs.mjs` | B3 | New file |
| `tools/ci/rewrite-workspace-refs.test.mjs` | B3 | New file |

### pn-infra-main (argo-ci chart)

| File | Phase | Action |
|------|-------|--------|
| `values.yaml` | A1, A3, F1 | Add secret entries, workspace StorageClass change |
| `templates/obc-nx-cache.yaml` | A2 | New file |
| `templates/workflow-pr-validation.yaml` | B1, E1, E4 | Full rewrite (RWO PVC, GitHub HTTPS clone, mutex) |
| `templates/workflow-post-merge-build.yaml` | B2, E1 | Full rewrite (RWO PVC, GitHub HTTPS clone, mutex) |
| `templates/pvc.yaml` | B1 | Update StorageClass to `app-blk-hdd-repl`, access mode to RWO |
| `templates/configmap-semaphore.yaml` | E3 | New file |

### pn-infra-main (other locations)

| File | Phase | Action |
|------|-------|--------|
| Argo Workflows controller config | E2 | Add Pod GC settings |
| `charts/tekton/` | F2 | Evaluate for removal |
| RFC-CICD-0001 `00-index.md` | F3 | Update status to Implemented |
| Platform spec doc | F4 | Update CI/CD section |
