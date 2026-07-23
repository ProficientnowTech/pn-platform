# SPEC-CICD-0001: Implementation Specification

**RFC:** RFC-CICD-0001 (Argo Workflows CI/CD Pipeline)
**Status:** Draft
**Date:** 2026-03-30
**Author:** Platform Engineering

---

## Scope

This specification describes the concrete implementation steps for the Argo
Workflows CI/CD pipeline defined in RFC-CICD-0001. It covers six groups of
changes across both the `pnow-ats-v2` (application) and `pn-infra-main`
(infrastructure) repositories.

**Repositories involved:**

| Repo | Branch | Path prefix |
|------|--------|-------------|
| `pnow-ats-v2` | `develop` / feature branches | `tools/ci/`, `nx.json`, `.nx/` |
| `pn-infra-main` | `v2` | `platform/stacks/developer-platform/charts/argo-ci/` |

**Current state of the argo-ci chart:**

The Helm chart at `platform/stacks/developer-platform/charts/argo-ci/` already
contains: EventBus, EventSource, Sensor (3 triggers: PR opened, merge-to-develop,
merge-to-main), two WorkflowTemplates (`pr-validation`, `post-merge-build`),
RBAC, Ingress, ExternalSecrets (5), a CephFS PVC (`ci-workspace`), and
Vault policy/auth resources. Both WorkflowTemplates currently mount the CephFS
PVC and use a mutex (`ci-workspace`) to serialize access.

**Current state of the DAG generator:**

`tools/ci/generate-argo-dag.mjs` reads `nx affected --graph=stdout`, builds an
Argo child workflow YAML from the task graph, and writes `affected-apps.json`
for the kaniko fan-out. It has unit tests. Known bug: `--graph=stdout` can
truncate large JSON payloads.

---

## Conventions

Each step follows this format:

- **Input** -- what must exist before the step can begin
- **Action** -- what to change (described concretely, no raw YAML/code blocks)
- **Output** -- what exists after the step completes
- **Validation** -- how to verify correctness (specific command or observable)

File paths are absolute from the repo root. "argo-ci chart" always means
`platform/stacks/developer-platform/charts/argo-ci/` in `pn-infra-main`.

---

## Group 1: Nx S3 Cache Configuration

**Goal:** Enable Nx Powerpack S3 remote cache backed by Ceph RGW so that
repeated lint/test/build runs across workflows reuse cached results.

### Step 1 -- Generate NX_KEY

- **Input:** Access to the Nx Powerpack dashboard (nx.dev account).
- **Action:** Run `npx nx register` in the pnow-ats-v2 workspace to obtain a
  Powerpack license key. Write the key to `.nx/key/key.ini` (this file is
  gitignored). The file format is a single line: the base64-encoded key string.
- **Output:** `.nx/key/key.ini` exists locally and Nx Powerpack features are
  unlocked (verify with `npx nx report` -- it should list Powerpack as active).
- **Validation:** `npx nx report | grep -i powerpack` shows an active license.

### Step 2 -- Add S3 cache configuration to nx.json

- **Input:** Step 1 complete. The Ceph RGW S3 endpoint is reachable (the OBC
  from step 4 provides the bucket and credentials).
- **Action:** In `pnow-ats-v2/nx.json`, add the `s3` configuration block at the
  top level, alongside the existing `cacheDirectory` field. Set the following
  properties:
  - `endpoint`: The Ceph RGW S3 endpoint URL (from the OBC ConfigMap).
  - `bucket`: The bucket name (from the OBC ConfigMap, e.g. `nx-cache-<hash>`).
  - `region`: `us-east-1` (Ceph default, required by the SDK but ignored by RGW).
  - `forcePathStyle`: `true` (Ceph RGW does not support virtual-hosted-style).
  - `disableChecksum`: `true` (Ceph RGW does not support the `x-amz-checksum-*`
    headers that the AWS SDK v3 sends by default; without this, uploads fail with
    a `501 Not Implemented` from RGW).
  This block is read by `@nx/powerpack-s3-cache` at runtime.
- **Output:** `nx.json` contains an `s3` key with the five properties above.
- **Validation:** `cat nx.json | jq '.s3'` returns a non-null object with all
  five fields populated.

### Step 3 -- Install @nx/powerpack-s3-cache

- **Input:** Step 2 complete. The package is not currently in `package.json`
  (confirmed: only `@nx/eslint`, `@nx/jest`, `@nx/next`, `@nx/storybook`,
  `@nx/web`, and `nx` are present as of 2026-03-30).
- **Action:** Run `pnpm add -D @nx/powerpack-s3-cache` in the pnow-ats-v2
  workspace root. This installs the Nx Powerpack S3 cache adapter. Verify the
  version is compatible with the installed `nx@21.6.3`.
- **Output:** `@nx/powerpack-s3-cache` appears in `devDependencies` of
  `package.json`. `pnpm-lock.yaml` is updated.
- **Validation:** `pnpm ls @nx/powerpack-s3-cache` shows the installed version.
  `npx nx report` lists S3 cache as an available runner.

### Step 4 -- Create nx-cache ObjectBucketClaim in argo namespace

- **Input:** Rook-Ceph Object Store is operational. The `CephObjectStore` and
  `StorageClass` for OBCs exist in the cluster.
- **Action:** In the argo-ci chart, add a new template file
  `templates/obc.yaml` that defines an `ObjectBucketClaim` (OBC) named
  `nx-cache` in the `argo` namespace. Set the `storageClassName` to the Ceph
  RGW OBC storage class (same class used by other OBCs in the platform). The
  OBC controller will provision a bucket and create two resources: a `ConfigMap`
  named `nx-cache` (containing `BUCKET_HOST`, `BUCKET_PORT`, `BUCKET_NAME`) and
  a `Secret` named `nx-cache` (containing `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`). These are used in step 6.
- **Output:** `templates/obc.yaml` exists in the argo-ci chart. When synced by
  ArgoCD, the OBC, ConfigMap, and Secret are created in the `argo` namespace.
- **Validation:** `kubectl get obc nx-cache -n argo` shows `Bound`.
  `kubectl get configmap nx-cache -n argo -o jsonpath='{.data.BUCKET_NAME}'`
  returns a non-empty bucket name. `kubectl get secret nx-cache -n argo` exists.

### Step 5 -- Create NX_KEY Kubernetes Secret

- **Input:** Step 1 complete (key value known). Vault is operational.
- **Action:** Store the Nx Powerpack key in Vault at path `ci/nx` with property
  `key`. Then add a new entry to the `secrets` map in the argo-ci chart's
  `values.yaml`:
  - Key: `nxKey`
  - `enabled`: true
  - `target`: `nx-key`
  - `data`: single entry mapping `secretKey: key` to `remoteRef: { key: ci/nx, property: key }`
  The existing `externalsecrets.yaml` template will render this automatically.
  Also extend the Vault policy in `templates/vault-policy.yaml` to ensure
  `ci/nx` is covered (it already covers `ci/*`, so no change is needed unless
  the path is outside that wildcard).
- **Output:** ExternalSecret `nx-key` exists in the `argo` namespace. It
  resolves to a Secret containing the Powerpack license key.
- **Validation:** `kubectl get externalsecret nx-key -n argo` shows
  `SecretSynced`. `kubectl get secret nx-key -n argo -o jsonpath='{.data.key}'
  | base64 -d` returns the key value.

### Step 6 -- Add NX_KEY and AWS credentials env vars to workflow templates

- **Input:** Steps 4 and 5 complete. The OBC ConfigMap/Secret and `nx-key`
  Secret all exist in the `argo` namespace.
- **Action:** In both `workflow-pr-validation.yaml` and
  `workflow-post-merge-build.yaml`, add environment variables to every container
  template that runs Nx commands (`pnpm-install`, `generate-task-dag`, and the
  `nx-task` template in generated child workflows). The env vars are:
  - `NX_KEY`: from Secret `nx-key`, key `key`
  - `AWS_ACCESS_KEY_ID`: from Secret `nx-cache`, key `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`: from Secret `nx-cache`, key `AWS_SECRET_ACCESS_KEY`
  - `NX_POWERPACK_LICENSE`: from Secret `nx-key`, key `key` (alias for tools
    that read this instead of `NX_KEY`)
  For the generated child workflow (produced by `generate-argo-dag.mjs`), the
  env vars must be injected by the DAG generator itself -- see step 19.
- **Output:** The WorkflowTemplate YAML files include `envFrom` or individual
  `env` entries referencing the two Secrets.
- **Validation:** Render the Helm chart locally with `helm template` and confirm
  the env vars appear in the relevant container specs. Grep the rendered output
  for `nx-key` and `nx-cache` to verify both Secrets are referenced.

---

## Group 2: Workspace Pattern Change

**Goal:** Replace the CephFS PVC (shared across all pods via mutex) with a
ContainerSet that uses a RWO block storage PVC for workspace persistence, and
S3 artifact passing for parallel kaniko builds. The RWO PVC retains the git
clone, pnpm store, and Nx local cache between runs. A mutex ensures only one
workflow uses the PVC at a time. Kaniko pods continue to use emptyDir with S3
artifact downloads.

### Step 7 -- Rewrite pr-validation to use ContainerSet with RWO PVC

- **Input:** Current `workflow-pr-validation.yaml` uses a DAG of independent
  container templates, each mounting the `ci-workspace` CephFS PVC.
- **Action:** Restructure the `pr-validation` WorkflowTemplate as follows.
  Replace the `git-sync`, `pnpm-install`, and `generate-dag` steps (which must
  run sequentially and share filesystem state) with a single `ContainerSet`
  template. A ContainerSet runs multiple containers in a single pod with a
  shared volume, enforcing ordering via container dependencies. The three
  containers are:
  1. `git-clone` -- fetches (or clones on cold start) directly from GitHub
     via HTTPS using the PAT from the `github-token` Secret into `/workspace`.
     If `/workspace/.git` already exists (warm PVC), runs `git fetch` +
     `git checkout`; otherwise runs `git clone`.
  2. `pnpm-install` -- runs `pnpm install --prefer-offline --frozen-lockfile`.
     The pnpm store directory on the PVC is reused across runs (hard links on
     the same block filesystem).
  3. `generate-dag` -- runs `generate-argo-dag.mjs`, writing outputs to `/tmp/`
  The ContainerSet pod mounts the RWO block PVC (`ci-workspace`, StorageClass
  `app-blk-hdd-repl`) at `/workspace`. Container dependencies enforce:
  `pnpm-install` depends on `git-clone`, `generate-dag` depends on
  `pnpm-install`. The `report-pending`, `submit-task-workflow`, and
  `report-success` steps remain as separate templates in the outer DAG, with
  `submit-task-workflow` depending on the ContainerSet step completing.
  Replace the old CephFS PVC reference with the RWO block PVC. Keep the
  `synchronization.mutex` (name: `ci-workspace`) to serialize access to the
  RWO PVC (only one workflow can mount it at a time).
- **Output:** `workflow-pr-validation.yaml` uses a ContainerSet backed by the
  RWO block PVC. Git operations target GitHub directly via HTTPS + PAT.
  Mutex serializes access.
- **Validation:** `helm template` renders without errors. The ContainerSet
  template contains exactly three containers with correct dependency ordering.
  The volume references `app-blk-hdd-repl` StorageClass (not `ceph-filesystem`).
  The git clone URL points to GitHub.

### Step 8 -- Rewrite post-merge-build to use ContainerSet with RWO PVC

- **Input:** Current `workflow-post-merge-build.yaml` uses a DAG of independent
  container templates with the `ci-workspace` CephFS PVC.
- **Action:** Apply the same ContainerSet + RWO PVC pattern as step 7. The
  setup ContainerSet includes four containers:
  1. `git-clone` -- fetches (or clones on cold start) directly from GitHub
     via HTTPS using the PAT from the `github-token` Secret
  2. `pnpm-install` -- installs dependencies (reuses cached pnpm store on PVC)
  3. `generate-dag` -- produces the task workflow YAML and affected-apps JSON
  4. `publish-to-verdaccio` -- publishes shared libraries (see step 14)
  Container dependencies: each depends on the previous. The ContainerSet
  outputs the workflow YAML and affected-apps JSON via output artifacts or
  output parameters (read from `/tmp/` paths). The outer DAG then proceeds to
  `submit-task-workflow`, then `kaniko-fan-out`, then `gitops-update`, then
  `slack-notify`.
  Replace the CephFS PVC with the RWO block PVC (`ci-workspace`, StorageClass
  `app-blk-hdd-repl`). Keep the `synchronization.mutex` to serialize PVC
  access.
- **Output:** `workflow-post-merge-build.yaml` uses ContainerSet backed by the
  RWO block PVC. Git operations target GitHub directly via HTTPS + PAT.
  Mutex serializes access.
- **Validation:** Same as step 7. Additionally, verify the
  `publish-to-verdaccio` container appears in the ContainerSet with a dependency
  on `generate-dag`. The git clone URL points to GitHub.

### Step 9 -- Configure S3 artifact upload for kaniko fan-out

- **Input:** Steps 7-8 complete (ContainerSet pattern in place). Ceph RGW S3
  is accessible from the `argo` namespace. Argo Workflows is configured with
  an S3 artifact repository (default or explicit).
- **Action:** Configure the Argo Workflows `default-artifact-repository` in the
  argo namespace ConfigMap (`artifact-repositories`) to point at a dedicated
  Ceph RGW bucket for workflow artifacts (separate from the Nx cache bucket).
  Alternatively, use inline artifact configuration on the ContainerSet output.
  After the ContainerSet completes, define an output artifact that tars the
  workspace source (excluding the `.git` directory, pnpm store, and Nx local
  cache -- those remain on the PVC for future runs). The tar includes the
  source code, compiled artifacts, root config files (`package.json`,
  `pnpm-lock.yaml`, `pnpm-workspace.yaml`, `nx.json`, `tsconfig.json`,
  `tsconfig.base.json`, `.npmrc`), and the rewritten `package.json` files.
  This tar is uploaded to S3 automatically by the Argo executor. The key path
  should include `{{workflow.name}}` to avoid collisions.
  Note: this S3 artifact is only needed for the kaniko fan-out, where each
  Kaniko pod downloads the tar into an emptyDir. The ContainerSet itself works
  directly on the RWO PVC and does not need S3 for its own operations.
- **Output:** The ContainerSet template declares an `outputs.artifacts` entry.
  After the ContainerSet pod completes, the tar exists in the S3 artifact bucket.
- **Validation:** Run a test workflow. After the ContainerSet step, check the S3
  bucket for the artifact: `aws s3 ls s3://<artifact-bucket>/` (using the RGW
  endpoint). The tar should exist and be non-trivially sized (hundreds of MB).

### Step 10 -- Configure kaniko steps to download S3 artifact

- **Input:** Step 9 complete. The workspace tar is in S3.
- **Action:** Modify the `kaniko-build` template to use an `inputs.artifacts`
  declaration that downloads the workspace tar from S3 into an `emptyDir`
  mounted at `/workspace`. This replaces the current PVC volumeMount. The
  `kaniko-fan-out` template must pass the artifact reference from the
  ContainerSet output through to each parallel kaniko instance. Since kaniko
  runs as a non-root user in a scratch image, the artifact must be extracted
  before kaniko starts -- use an init container or the Argo artifact extraction
  (which unpacks tars automatically into the specified path).
  Also add the `rewrite-workspace-refs` step output (see step 16) to the
  workspace so that `package.json` files reference Verdaccio URLs instead of
  `workspace:*` protocols.
- **Output:** `kaniko-build` template uses S3 input artifact + emptyDir. No
  PVC volumeMount.
- **Validation:** `helm template` output shows no `persistentVolumeClaim` in
  the kaniko-build template. The `inputs.artifacts` block references the S3
  key pattern.

### Step 11 -- Replace CephFS PVC with RWO block PVC

- **Input:** Steps 7-10 complete. Both WorkflowTemplates reference the new PVC
  type.
- **Action:** Update the `pvc.yaml` template in the argo-ci chart (or create a
  new `pvc-workspace.yaml`) to define the `ci-workspace` PVC with:
  - StorageClass: `app-blk-hdd-repl` (RWO block storage, NOT `ceph-filesystem`)
  - Access mode: `ReadWriteOnce`
  - Size: 20Gi (same as before, tunable via `values.yaml`)
  Update the `workspace` section in `values.yaml` to reflect the new
  StorageClass. Keep the `synchronization.mutex` (`ci-workspace`) in both
  WorkflowTemplates to serialize access to the RWO PVC.
  If the old CephFS PVC `ci-workspace` already exists in the cluster, it must
  be deleted before the new RWO PVC can be created with the same name (since
  StorageClass cannot be changed on an existing PVC). Coordinate this with a
  brief CI downtime window.
- **Output:** The `ci-workspace` PVC uses `app-blk-hdd-repl` StorageClass. Both
  WorkflowTemplates mount it and use the mutex for serialized access.
- **Validation:** `kubectl get pvc ci-workspace -n argo -o jsonpath='{.spec.storageClassName}'`
  returns `app-blk-hdd-repl`. Both workflows mount the PVC and the mutex is
  active. Trigger a workflow and confirm it acquires the mutex before running.

---

## Group 3: Verdaccio CI Publishing

**Goal:** Publish shared libraries (`shared/*`) to Verdaccio during post-merge
builds, and rewrite `workspace:*` references in service `package.json` files to
point at Verdaccio-hosted versions. This eliminates the need for kaniko builds
to have access to the full monorepo node_modules.

### Step 12 -- Create Verdaccio token and store in Vault

- **Input:** Verdaccio is running at `npm.pnats.cloud`. Vault is operational.
- **Action:** Generate a Verdaccio authentication token. This can be done by
  logging in via `npm login --registry=https://npm.pnats.cloud` and extracting
  the token from `~/.npmrc`, or by using the Verdaccio API directly. Store the
  token in Vault at path `ci/verdaccio` with property `token`. The token must
  have publish permissions for the `@pnats` scope.
- **Output:** Vault path `ci/verdaccio` contains `{ "token": "<base64-token>" }`.
- **Validation:** `vault kv get secret/ci/verdaccio` returns the token (from a
  machine with Vault CLI access). Alternatively, use the Vault UI to verify.

### Step 13 -- Add ExternalSecret for Verdaccio token

- **Input:** Step 12 complete. The Vault path exists.
- **Action:** Add a new entry to the `secrets` map in the argo-ci chart's
  `values.yaml`:
  - Key: `verdaccioToken`
  - `enabled`: true
  - `target`: `verdaccio-token`
  - `data`: single entry mapping `secretKey: token` to
    `remoteRef: { key: ci/verdaccio, property: token }`
  The existing `externalsecrets.yaml` template renders this automatically.
- **Output:** ExternalSecret `verdaccio-token` renders in the Helm output.
  When synced, it creates a Secret `verdaccio-token` in the `argo` namespace.
- **Validation:** `helm template | grep verdaccio-token` shows the
  ExternalSecret. After ArgoCD sync: `kubectl get secret verdaccio-token -n argo`.

### Step 14 -- Add publish-to-verdaccio step in post-merge-build

- **Input:** Steps 8 and 13 complete. The Verdaccio Secret exists.
- **Action:** In the `post-merge-build` WorkflowTemplate, the
  `publish-to-verdaccio` container within the ContainerSet (added in step 8)
  runs:
  1. Configure npm auth: write an `.npmrc` file in `/workspace` that sets
     `//npm.pnats.cloud/:_authToken=${VERDACCIO_TOKEN}` and
     `@pnats:registry=https://npm.pnats.cloud`
  2. Run `pnpm publish -r --no-git-checks --filter './shared/*'` to publish all
     shared libraries. The `--no-git-checks` flag is necessary because the
     working directory is a detached HEAD checkout.
  The container receives the `VERDACCIO_TOKEN` env var from the `verdaccio-token`
  Secret.
  The `npm-publish` template currently runs `npx nx release publish --yes`.
  Replace this with the Verdaccio-specific publish command above, or rename it
  to clarify its role. If `nx release publish` is still needed for GitHub
  releases, keep it as a separate step that runs only on main-branch merges.
- **Output:** The `publish-to-verdaccio` container exists in the ContainerSet.
  Shared libraries are published to Verdaccio on every post-merge build.
- **Validation:** After a post-merge run, verify packages exist in Verdaccio:
  `npm view @pnats/core --registry=https://npm.pnats.cloud` returns the latest
  version.

### Step 15 -- Create rewrite-workspace-refs script

- **Input:** pnow-ats-v2 monorepo uses `workspace:*` protocol in service
  `package.json` files to reference shared libraries.
- **Action:** Create `pnow-ats-v2/tools/ci/rewrite-workspace-refs.mjs`. This
  script:
  1. Reads the root `pnpm-workspace.yaml` to discover all workspace packages
  2. For each package, reads its `package.json` to get `name` and `version`
  3. Walks every `package.json` in the workspace and replaces any
     `"workspace:*"` or `"workspace:^"` version specifier with the concrete
     version string (e.g., `"^1.2.3"`)
  4. Writes the modified `package.json` files back in place
  This transformation is necessary because kaniko builds run in isolation without
  access to the full workspace's node_modules symlinks. With concrete versions,
  `pnpm install` inside the Dockerfile resolves packages from Verdaccio.
- **Output:** `tools/ci/rewrite-workspace-refs.mjs` exists with unit tests at
  `tools/ci/rewrite-workspace-refs.test.mjs`.
- **Validation:** Run the script locally in a clean checkout, then inspect any
  service's `package.json` -- `workspace:*` entries should be replaced with
  semver ranges. The change should be reversible with `git checkout -- .`.

### Step 16 -- Add rewrite step before kaniko fan-out

- **Input:** Steps 15 and 14 complete. The rewrite script exists and Verdaccio
  has published packages.
- **Action:** In the `post-merge-build` WorkflowTemplate, add a
  `rewrite-workspace-refs` container to the ContainerSet, running after
  `publish-to-verdaccio` and before the ContainerSet outputs are captured for
  the kaniko fan-out. The container runs
  `node tools/ci/rewrite-workspace-refs.mjs` in the `/workspace` directory.
  This ensures the workspace tar uploaded to S3 (step 9) contains rewritten
  `package.json` files, so kaniko builds can resolve `@pnats/*` packages from
  Verdaccio instead of relying on workspace symlinks.
  Update the ContainerSet dependency chain:
  `git-clone` -> `pnpm-install` -> `generate-dag` -> `publish-to-verdaccio` -> `rewrite-workspace-refs`
- **Output:** The ContainerSet includes five containers. The workspace tar
  uploaded to S3 contains rewritten `package.json` files.
- **Validation:** After a post-merge build, download the S3 artifact tar and
  inspect a service's `package.json` -- it should contain concrete versions,
  not `workspace:*`.

---

## Group 4: generate-argo-dag.mjs Fixes

**Goal:** Fix known bugs and add S3 cache support to the DAG generator.

### Step 17 -- Switch from --graph=stdout to --graph=/tmp/graph.json

- **Input:** Current `generate-argo-dag.mjs` line 242-244 uses
  `nx affected -t ${TARGETS} --base=... --head=... --graph=stdout` and parses
  the result as JSON. This truncates on large monorepos because stdout buffering
  in `execSync` has a default `maxBuffer` of ~1MB.
- **Action:** Change the `execSync` call to write the graph to a file:
  `npx nx affected -t ${TARGETS} --base=${BASE_SHA} --head=${HEAD_SHA} --graph=/tmp/graph.json`
  Then read the file with `fs.readFileSync('/tmp/graph.json', 'utf8')` and
  parse it. This avoids the stdout truncation issue entirely because the file
  write is unbuffered. Apply the same change to the project graph call on
  line 278 (`npx nx graph --file=stdout` -> `--file=/tmp/project-graph.json`).
- **Output:** `generate-argo-dag.mjs` reads graph data from files, not stdout.
- **Validation:** Run the existing unit tests: `npx jest tools/ci/generate-argo-dag.test.mjs`.
  They should still pass (the tests mock `execSync` so the file I/O change
  requires updating the mocks to write files instead of returning stdout).
  Additionally, run the script manually against a real workspace with
  `BASE_SHA=HEAD~5 HEAD_SHA=HEAD` and verify `/tmp/graph.json` is valid JSON.

### Step 18 -- Handle empty affected list gracefully

- **Input:** The `generateWorkflowYaml` function already handles empty
  `dagTasks` by producing a no-op workflow. However, `buildAffectedApps` can
  return an empty array, and the post-merge-build template's `kaniko-fan-out`
  step receives this empty array via `withParam`. Argo Workflows treats an
  empty `withParam` list as zero iterations, which is correct, but the
  `gitops-update` step should also be skipped.
- **Action:** In `generate-argo-dag.mjs`, when the affected apps list is empty,
  write `[]` to `/tmp/affected-apps.json` (already the case). In the
  `post-merge-build` WorkflowTemplate, add a `when` condition to the
  `docker-builds`, `update-gitops`, and `notify` DAG tasks that checks whether
  the affected-apps parameter is a non-empty JSON array (e.g.,
  `when: "{{tasks.generate-dag.outputs.parameters.affected-apps}} != '[]'"`).
  This prevents Argo from attempting to run kaniko with no services, or
  committing a no-change gitops update.
- **Output:** Empty affected lists result in the workflow completing
  successfully without running kaniko, gitops-update, or slack-notify.
- **Validation:** Simulate by setting BASE_SHA and HEAD_SHA to the same commit
  (producing zero affected projects). The workflow should succeed with the
  kaniko, gitops-update, and notify steps showing as "Skipped".

### Step 19 -- Add Nx S3 cache env vars to generated child workflow pods

- **Input:** Steps 5-6 complete. The NX_KEY and AWS credential Secrets exist.
  The child workflow YAML is generated by `generateWorkflowYaml()` in
  `generate-argo-dag.mjs`.
- **Action:** Modify `generateWorkflowYaml()` to inject environment variables
  into the `nx-task` template's container spec. The env vars are:
  - `NX_KEY` from Secret `nx-key`, key `key`
  - `AWS_ACCESS_KEY_ID` from Secret `nx-cache`, key `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY` from Secret `nx-cache`, key `AWS_SECRET_ACCESS_KEY`
  These are the same vars as step 6, but they must be rendered into the child
  workflow YAML string because the child workflow is a standalone Workflow
  resource (not a WorkflowTemplate that inherits env from the parent).
  The Secret names (`nx-key`, `nx-cache`) should be read from environment
  variables (`NX_KEY_SECRET_NAME`, `NX_CACHE_SECRET_NAME`) passed to the
  `generate-task-dag` template, with defaults of `nx-key` and `nx-cache`.
  Additionally, accept a `CACHE_MODE` env var and, if set, include
  `NX_POWERPACK_CACHE_MODE` in the generated env block (used in step 23).
- **Output:** Generated child workflow YAML includes `env` entries with
  `valueFrom.secretKeyRef` for all three S3 cache credentials.
- **Validation:** Run the unit tests with updated expectations. Also run the
  generator locally and inspect `/tmp/task-workflow.yaml` -- the `nx-task`
  template should contain `secretKeyRef` entries for `nx-key` and `nx-cache`.

---

## Group 5: Pipeline Hardening

**Goal:** Add timeouts, Pod GC, concurrency controls, and cache safety to
prevent runaway workflows and resource leaks.

### Step 20 -- Set activeDeadlineSeconds on all workflow templates

- **Input:** Current state: only the `generate-task-dag` template has
  `activeDeadlineSeconds: 600`. The parent WorkflowTemplates and child workflow
  have no timeout.
- **Action:** Add `activeDeadlineSeconds` at the workflow spec level (not
  individual template level) in both WorkflowTemplates:
  - `pr-validation`: 1800 seconds (30 minutes). PR validation should not take
    longer than this; if it does, something is stuck.
  - `post-merge-build`: 3600 seconds (60 minutes). Docker builds for 18 services
    can take up to 45 minutes; 60 provides headroom.
  Also add `activeDeadlineSeconds: 1800` to the generated child workflow spec
  in `generateWorkflowYaml()` (the child DAG runs lint/test/build tasks and
  should complete within 30 minutes).
- **Output:** All three workflow specs (two templates + generated child) have
  `activeDeadlineSeconds` set.
- **Validation:** `helm template | grep activeDeadlineSeconds` returns values
  for both WorkflowTemplates. Inspect the generated child YAML for the field.

### Step 21 -- Configure Pod GC

- **Input:** Argo Workflows supports `podGC` at the workflow spec level.
- **Action:** Add `podGC` to both WorkflowTemplate specs and to the generated
  child workflow:
  - `strategy: OnPodCompletion` -- delete pods as soon as their step completes
    successfully.
  - `deleteDelayDuration: 60s` -- keep completed pods for 60 seconds for log
    collection, then delete.
  - For failed pods, Argo's default behavior retains them. Add
    `labelSelector.matchLabels` with `workflows.argoproj.io/completed: "true"`
    to target only completed pods. Failed pods are kept for debugging (up to
    the `activeDeadlineSeconds` + GC sweep interval).
- **Output:** `podGC` block in all workflow specs.
- **Validation:** After a successful workflow run, observe that completed pods
  are cleaned up within ~60 seconds:
  `kubectl get pods -n argo -l workflows.argoproj.io/workflow=<name>` should
  show only running or recently-completed pods, not pods from finished steps.

### Step 22 -- Add semaphore ConfigMap for concurrency control

- **Input:** The mutex (`ci-workspace`) is being removed in step 11. Without
  any concurrency control, many workflows could run simultaneously and exhaust
  cluster resources.
- **Action:** Create a new template file `templates/semaphore.yaml` in the
  argo-ci chart that defines a ConfigMap named `ci-semaphore` in the `argo`
  namespace. The ConfigMap has two keys:
  - `pr-validation`: `"3"` -- allow up to 3 concurrent PR validation workflows
  - `post-merge-build`: `"1"` -- allow only 1 concurrent post-merge build
    (serializes Docker pushes and gitops updates to avoid race conditions)
  In `workflow-pr-validation.yaml`, replace the mutex with a semaphore:
  `synchronization.semaphore.configMapKeyRef: { name: ci-semaphore, key: pr-validation }`
  In `workflow-post-merge-build.yaml`:
  `synchronization.semaphore.configMapKeyRef: { name: ci-semaphore, key: post-merge-build }`
  The semaphore values are tunable via the ConfigMap without redeploying the chart.
- **Output:** `templates/semaphore.yaml` exists. Both WorkflowTemplates use
  semaphore synchronization instead of mutex.
- **Validation:** `helm template | grep -A3 semaphore` shows the ConfigMap
  reference in both WorkflowTemplates. After deploy, run 4 concurrent PR
  validation workflows -- the 4th should queue (visible in Argo UI as "Pending").

### Step 23 -- Set cache read-only for PR validation

- **Input:** Steps 6 and 19 complete. Nx S3 cache is available to all workflows.
- **Action:** In the `pr-validation` WorkflowTemplate, pass an additional env
  var to the `generate-task-dag` template: `CACHE_MODE=read-only`. This flows
  through to `generate-argo-dag.mjs` (step 19) which injects
  `NX_POWERPACK_CACHE_MODE=read-only` into the child workflow's `nx-task`
  containers. This prevents PR validation runs from polluting the cache with
  potentially broken builds (CREEP mitigation -- only post-merge builds, which
  run on verified code, write to the cache).
  In `post-merge-build`, do NOT set `CACHE_MODE` (or set it to `read-write`
  explicitly), so post-merge builds both read from and write to the cache.
- **Output:** PR validation child workflow pods have
  `NX_POWERPACK_CACHE_MODE=read-only`. Post-merge child workflow pods do not
  have this env var (defaults to read-write).
- **Validation:** Trigger a PR validation workflow. Inspect the child workflow's
  pod spec: `kubectl get workflow <child-name> -n argo -o yaml | grep CACHE_MODE`
  should show `read-only`. Trigger a post-merge build and verify the same
  grep returns no match (or `read-write`).

---

## Group 6: Verification

**Goal:** End-to-end validation that the complete pipeline works as specified.

### Step 24 -- PR validation end-to-end

- **Input:** All prior steps complete. A feature branch exists with at least one
  changed file.
- **Action:** Open a pull request against `develop` from the feature branch.
  This triggers the `pr-opened` sensor dependency, which submits a
  `pr-validation` workflow.
- **Output:** The workflow runs through: ContainerSet (git-clone, pnpm-install,
  generate-dag) -> submit child workflow (lint/test/build DAG) -> report
  success. The GitHub commit status shows a green check.
- **Validation:**
  - `argo list -n argo --selector pipeline=pr-validation` shows the workflow
    with status `Succeeded`.
  - GitHub PR page shows the `argo-ci/validation` status check as passing.
  - `argo get <workflow-name> -n argo` shows all steps completed.

### Step 25 -- Post-merge build end-to-end

- **Input:** Step 24 passed. The PR is ready to merge.
- **Action:** Merge the PR to `develop`. This triggers the `pr-merged-develop`
  sensor dependency, which submits a `post-merge-build` workflow.
- **Output:** The workflow runs through: ContainerSet (git-clone, pnpm-install,
  generate-dag, publish-to-verdaccio, rewrite-workspace-refs) -> submit child
  workflow (build DAG) -> kaniko fan-out -> gitops-update -> slack-notify.
  Docker images are pushed to Harbor.
- **Validation:**
  - `argo list -n argo --selector pipeline=post-merge` shows `Succeeded`.
  - `curl -s https://registry.pnats.cloud/v2/pnats/api-gateway/tags/list`
    includes the merge commit SHA as a tag.
  - Harbor UI shows recently-pushed images for all affected services.

### Step 26 -- Gitops update verification

- **Input:** Step 25 completed. The `gitops-update` step pushed a commit to
  `pn-infra-main` on branch `v2`.
- **Action:** Inspect the latest commit on the `v2` branch of pn-infra.
- **Output:** The commit message is
  `chore(deploy): update image tags to <sha>`. The kustomization overlay files
  under `business/apps/pnats/overlays/staging/kustomization.yaml` have
  `newTag` values matching the merge commit SHA for all affected services.
  ArgoCD detects the change and syncs (auto-sync is enabled for staging).
- **Validation:**
  - `git -C ~/work/pn-infra-main log -1 --oneline origin/v2` shows the
    `chore(deploy)` commit.
  - `kubectl get pods -n pnats-staging -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'`
    shows the new image tags on affected services.
  - ArgoCD UI shows `pnats-staging` as Synced and Healthy.

### Step 27 -- Nx S3 cache populated

- **Input:** Step 25 completed (post-merge build ran with cache write enabled).
- **Action:** Inspect the Nx cache S3 bucket.
- **Output:** The bucket contains cache entries (tar files or directories)
  corresponding to the lint/test/build task hashes.
- **Validation:** Using the OBC credentials:
  `aws --endpoint-url=<rgw-endpoint> s3 ls s3://<nx-cache-bucket>/ --recursive | head -20`
  should show multiple cache entries. The total size should be non-trivial
  (tens to hundreds of MB depending on how many tasks ran).

### Step 28 -- Cache hits on second run

- **Input:** Step 27 confirmed cache is populated.
- **Action:** Trigger another post-merge build (e.g., merge a docs-only change
  that still affects the same set of projects, or retrigger the same SHA).
  Alternatively, push a trivial change to a single service and merge.
- **Output:** The child workflow completes faster than the first run because
  Nx resolves most tasks from the S3 cache.
- **Validation:** Compare workflow durations in the Argo UI. The second run
  should be noticeably faster (at least 30-50% reduction for cached targets).
  In the workflow logs for individual `nx-task` pods, look for
  `[remote cache]` or `Nx read the output from the cache` messages confirming
  cache hits.

### Step 29 -- Shared library change triggers dependent services

- **Input:** S3 cache is populated from previous runs.
- **Action:** Make a change to a shared library (e.g., modify a file in
  `shared/core/src/`). Create a PR, verify the PR validation workflow includes
  dependent services in the DAG. Merge to `develop` and verify the post-merge
  build triggers kaniko builds for all services that depend on `@pnats/core`.
- **Output:** `affected-apps.json` includes all dependent services. Kaniko
  builds run for those services. Services that do NOT depend on `@pnats/core`
  are absent from the list.
- **Validation:**
  - In the `generate-dag` step logs, the affected project list includes
    dependent services (e.g., `api-gateway`, `auth-service`, etc.).
  - `kubectl logs <generate-dag-pod> -n argo` or Argo UI logs show the full
    affected-apps JSON.
  - Harbor shows new image tags for dependent services but NOT for unrelated
    ones (e.g., `web` should not be rebuilt if only `shared/core` changed,
    unless `web` actually depends on `@pnats/core`).

---

## Acceptance Criteria

These criteria map directly to the RFC requirements. All must pass for the
implementation to be considered complete.

| # | Criterion | How to verify |
|---|-----------|---------------|
| AC-1 | PR open triggers workflow that runs clone, install, lint/test/build and reaches `Succeeded` | Step 24 validation |
| AC-2 | Merge to develop triggers workflow that builds Docker images and pushes to Harbor, reaching `Succeeded` | Step 25 validation |
| AC-3 | gitops-update commits image tags to pn-infra `v2` branch, ArgoCD syncs and deploys | Step 26 validation |
| AC-4 | GitHub commit status on PR shows pass/fail from `argo-ci/validation` context | Step 24 -- check GitHub PR status checks |
| AC-5 | Nx S3 cache bucket contains entries after first post-merge build | Step 27 validation |
| AC-6 | Second run shows cache hits (faster execution, `[remote cache]` in logs) | Step 28 validation |
| AC-7 | Change to `shared/core` triggers dependent service builds (not all services) | Step 29 -- affected-apps.json contains only dependents |
| AC-8 | Isolated service change (e.g., only `api-gateway`) does NOT trigger unrelated builds | Step 29 inverse -- verify non-dependents are absent from affected-apps.json |
| AC-9 | Workflow git-clone step fetches directly from GitHub via HTTPS + PAT | Step 24/25 -- remote URL in git-clone logs is a GitHub URL |
| AC-10 | Warm-start git fetch completes in under 10 seconds | Step 24/25 -- timed from workflow step logs on a pre-populated PVC |

---

## Dependency Graph

```
Step 1 ──────┐
Step 2 ──────┤
Step 3 ──────┼── Step 6 ── Step 19 ── Step 23
Step 4 ──────┤
Step 5 ──────┘

Step 7 ──────┐
Step 8 ──────┼── Step 9 ── Step 10 ── Step 11
             │
Step 12 ─────┤
Step 13 ─────┼── Step 14 ── Step 16
Step 15 ─────┘

Step 17 ─────┐
Step 18 ─────┼── (independent, merge to main branch)
Step 19 ─────┘

Step 20 ─────┐
Step 21 ─────┼── (independent, merge to main branch)
Step 22 ─────┤
Step 23 ─────┘

Steps 24-29: sequential, require all above complete
```

**Parallelizable work:**

- Groups 1, 2, 3, and 4 can proceed in parallel on separate branches.
  Group 2 and Group 3 (Verdaccio) have a merge dependency (step 8 adds the
  container that step 14 populates).
- Group 5 (hardening) can be done independently at any time.
- Group 6 (verification) is strictly serial and last.

---

## Rollback Plan

If the implementation fails at any group:

- **Group 1 (S3 cache):** Remove `s3` block from `nx.json`, remove
  `@nx/powerpack-s3-cache` from dependencies. Nx falls back to local cache.
  No data loss.
- **Group 2 (workspace pattern):** Revert WorkflowTemplate changes to use the
  CephFS PVC and its StorageClass. Revert the PVC StorageClass from
  `app-blk-hdd-repl` back to `ceph-filesystem`.
- **Group 3 (Verdaccio):** Remove the publish and rewrite steps from the
  ContainerSet. Kaniko builds fall back to the full workspace context (requires
  PVC or full workspace tar). No impact on published packages (Verdaccio is
  append-only).
- **Group 4 (DAG generator fixes):** Revert `generate-argo-dag.mjs` changes.
  The old `--graph=stdout` behavior returns (with the truncation risk).
- **Group 5 (hardening):** Remove timeouts, podGC, and semaphore. Workflows
  return to unbounded execution. This is undesirable but safe.

---

## Files Modified (Summary)

### pnow-ats-v2

| File | Change |
|------|--------|
| `nx.json` | Add `s3` configuration block |
| `package.json` | Add `@nx/powerpack-s3-cache` dev dependency |
| `.nx/key/key.ini` | New file (gitignored), Nx Powerpack key |
| `tools/ci/generate-argo-dag.mjs` | Fix --graph=stdout, add S3 env vars to child workflow, handle empty affected |
| `tools/ci/generate-argo-dag.test.mjs` | Update mocks for file-based graph reading, add env var assertions |
| `tools/ci/rewrite-workspace-refs.mjs` | New file, rewrites workspace:* to concrete versions |
| `tools/ci/rewrite-workspace-refs.test.mjs` | New file, unit tests for rewrite script |

### pn-infra-main

| File | Change |
|------|--------|
| `charts/argo-ci/values.yaml` | Add `nxKey` and `verdaccioToken` secrets, workspace StorageClass change to `app-blk-hdd-repl` |
| `charts/argo-ci/templates/workflow-pr-validation.yaml` | ContainerSet with RWO PVC, mutex, GitHub HTTPS clone, semaphore, timeout, podGC, S3 env vars, cache read-only |
| `charts/argo-ci/templates/workflow-post-merge-build.yaml` | ContainerSet with RWO PVC, mutex, GitHub HTTPS clone, semaphore, timeout, podGC, S3 env vars, Verdaccio publish, rewrite step, S3 artifact, when-guards |
| `charts/argo-ci/templates/obc.yaml` | New file, ObjectBucketClaim for nx-cache |
| `charts/argo-ci/templates/semaphore.yaml` | New file, ConfigMap for concurrency limits |

All paths under `charts/argo-ci/` are relative to
`platform/stacks/developer-platform/` in the `pn-infra-main` repo.
