# CI Pipeline Session Log — 2026-04-04

## What Was Done (completed)

### Phase A: Foundation
- nx-cache OBC created in argo namespace
- nx-cache-server deployed (Deployment + Service)
- nx-cache-server auth token in Vault (applications/ci/nx-cache-server)
- Verdaccio ExternalSecret (templates from Vault robot creds)
- All Vault paths migrated from ci/* to applications/ci/* (works with existing policy)
- Root cause found: vault-initializer sidecar was overwriting policy in a loop; created `admins` identity group to stop it

### Phase B: Workflow Rewrite
- pr-validation WorkflowTemplate: ContainerSet + RWO PVC + HTTPS+PAT git clone
- post-merge-build WorkflowTemplate: ContainerSet + kaniko fan-out via S3 artifacts
- rewrite-workspace-refs.mjs created (20 tests passing)
- generate-argo-dag.mjs fixed (file-based graph output)
- All templates documented with headers
- Chart README written
- Chart moved from platform/stacks/developer-platform/charts/argo-ci to business/ci/pnats-ci
- Chart renamed from pn-argo-ci to pnats-ci
- ArgoCD Application updated in business/apps/pnats/application.yaml

### Harbor Robot Account
- Crossplane-managed RobotAccount created (robot$pnats+pnats-ci-robot)
- PushSecret syncs password to Vault
- ExternalSecret pulls and templates into dockerconfigjson
- Username is robot$pnats+pnats-ci-robot (project-level prefix)

### RFC Documentation
- RFC-CICD-0001 written (9 files, standards-compliant)
- Implementation spec (SPEC-CICD-0001-implementation.md)
- Execution plan (PLAN-CICD-0001-execution.md)
- RFC moved to rfcs repo at content/docs/platform/cicd/

### Frameworks Created
- Engineering Execution Framework (7 phases)
- Diagnostic Framework (7 phases)
- Operations Framework (5 phases)

## Current Blocking Issue

### Harbor 500 Internal Server Error

**Root cause chain:**
1. The original OBC `harbor-registry` auto-created a Secret with S3 credentials
2. Harbor's upstream Helm chart ALSO creates a Secret called `harbor-registry` (for REGISTRY_REDIS_PASSWORD)
3. Helm overwrites the OBC's Secret → registry lost S3 credentials
4. We renamed the OBC to `harbor-s3-creds` to avoid the conflict
5. ArgoCD pruned the old `harbor-registry` OBC → Ceph RGW deleted the old user that owned the bucket
6. The new OBC user can't access objects written by the old user (S3 bucket ACL)
7. The Vault-stored credentials (from the old user) are stale — that user no longer exists
8. Result: `s3aws: AccessDenied: status code: 403` from the registry

**Also:** The Harbor chart template still renders `envFrom: harbor-storage-s3` from a template we deleted but ArgoCD hasn't synced yet. The API server instability prevents clean syncs.

## What's Next

### Immediate fix for Harbor:
Option A (simplest): Repush ci-tools image from local Docker cache using new OBC credentials, then update chart to use harbor-s3-creds secret only
Option B (proper): Transfer bucket ownership to the new user via radosgw-admin, then update credentials

Steps:
1. Ensure Harbor chart has `existingSecret: harbor-s3-creds` and NO reference to `harbor-storage-s3`
2. Sync Harbor app cleanly (wait for API server stability)
3. Verify registry pod gets new OBC credentials (LFQCF6...)
4. Repush ci-tools image: `docker push registry.pnats.cloud/pnats/ci-tools:latest`
5. Test manifest pull

### After Harbor is fixed:
1. Retrigger CI PR validation test
2. Watch full workflow to Succeeded
3. Test post-merge build
4. Phase E: Hardening (deadlines, Pod GC, semaphore, cache read-only)
5. Phase F: Cleanup (remove old Tekton resources)

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| pnats-ci chart | business/ci/pnats-ci/ | All CI infrastructure |
| Harbor chart | platform/stacks/developer-platform/charts/harbor/ | Harbor config including S3 |
| RFC-CICD-0001 | docs/platform/rfcs/cicd/RFC-CICD-0001/ (pn-infra) + content/docs/platform/cicd/ (rfcs repo) | Architecture RFC |
| Implementation spec | docs/platform/rfcs/cicd/SPEC-CICD-0001-implementation.md | Concrete steps |
| Execution plan | docs/platform/rfcs/cicd/PLAN-CICD-0001-execution.md | Phased plan |
| CI scripts | pnow-ats-v2/tools/ci/ | generate-argo-dag.mjs, service-config.mjs, rewrite-workspace-refs.mjs |
| Frameworks | ~/.claude/skills/ | engineering-execution-framework.md, diagnostic-framework.md, operations-framework.md |
| Deferred items | docs/platform/ci-deferred-items.md | Everything not yet done |

## Cluster Issues to Address Separately
- API server (192.168.100.2:6443) has frequent connection refused errors
- Ceph HEALTH_WARN with degraded objects (1.9%)
- Vault HA instability (nodes lose leader, auto-unsealer needed)
- Crossplane Vault provider can't detect policy content drift (workaround: vault-initializer now stopped by admins group)
