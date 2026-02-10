```
RFC-RFCSTD-0003                                                   Section 6
Category: Standards Track                                         Examples
```

# 6. Examples

[← Validation](./05-validation.md) | [Index](./00-index.md) | [Next →](./appendix-a-glossary.md)

---

## 6.1 Prerequisites Example

**Well-Formed Prerequisites:**

```markdown
## Infrastructure Prerequisites

| Prerequisite | Type | Version | Verification |
|--------------|------|---------|--------------|
| Kubernetes cluster | Required | 1.28+ | `kubectl version --short` shows v1.28+ |
| Helm | Required | 3.12+ | `helm version --short` shows v3.12+ |
| Vault connectivity | Required | N/A | `vault status` succeeds |

## Access Prerequisites

| Prerequisite | Type | Version | Verification |
|--------------|------|---------|--------------|
| Vault admin token | Required | N/A | Can list secrets in kv/ |
| Kubernetes admin | Required | N/A | Can create namespaces |
| Azure AD access | Conditional | N/A | Only if federating identity |
```

This demonstrates:

| Property | Value |
|----------|-------|
| Categorization | Infrastructure, Access |
| Types | Required, Conditional |
| Verification | Specific commands or checks |

---

## 6.2 Phase Example

**Well-Formed Phase:**

```markdown
## Phase 3: Configure Secret Synchronization

### Tasks

| Task | Description | Outcome |
|------|-------------|---------|
| 3.1 | Create SecretStore resource | SecretStore exists in namespace |
| 3.2 | Create ExternalSecret resources | ExternalSecrets exist |
| 3.3 | Verify Kubernetes Secrets created | Secrets populated from Vault |

### Test

| Verification | Method | Expected Result |
|--------------|--------|-----------------|
| SecretStore ready | Check SecretStore status | Ready: true |
| ExternalSecrets synced | Check ExternalSecret status | Synced: true |
| Secrets populated | Check Secret data | Non-empty values |

### Iterate

| Checkpoint | Proceed If | Rollback If |
|------------|------------|-------------|
| All secrets synced | Continue to Phase 4 | Execute Phase 3 Rollback |
| Sync errors | Investigate and retry | If unrecoverable, rollback |

### Rollback

| Step | Action |
|------|--------|
| 3.R1 | Delete ExternalSecret resources |
| 3.R2 | Delete SecretStore resource |
| 3.R3 | Delete created Kubernetes Secrets |
```

---

## 6.3 Resource Table Example

**Well-Formed Resource Table:**

```markdown
## Kubernetes Resources

| Resource | Type | Namespace | Purpose | Dependencies |
|----------|------|-----------|---------|--------------|
| eso-secretstore | SecretStore | platform-secrets | Vault connection config | Namespace, Vault token |
| eso-db-secret | ExternalSecret | app-namespace | Database credentials | SecretStore |
| db-credentials | Secret | app-namespace | Synchronized db creds | ExternalSecret |

## Resource Details: eso-secretstore

| Attribute | Value |
|-----------|-------|
| Name | eso-secretstore |
| Type | SecretStore (ESO CRD) |
| Namespace | platform-secrets |
| Purpose | Configure Vault backend for ESO |
| Backend | Vault at vault.platform.svc |
| Auth Method | Kubernetes service account |
| Dependencies | Vault must be accessible, SA must exist |
| Validation | Status shows Ready: true |
```

**NOT Permitted:**

```yaml
# This would NOT be permitted
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: eso-secretstore
spec:
  provider:
    vault:
      server: "https://vault.platform.svc"
```

---

## 6.4 Validation Criteria Example

**Well-Formed Validation Criteria:**

```markdown
## Validation Criteria

| ID | Criterion | Method | Pass Condition |
|----|-----------|--------|----------------|
| V1 | ESO controller running | Check deployment status | All replicas ready |
| V2 | SecretStore connected | Check SecretStore status | Status.Ready = true |
| V3 | Secrets synced | Check ExternalSecret status | Status.SyncedResourceVersion present |
| V4 | Secret data valid | Decode and verify secret | Contains expected keys |
| V5 | Application can use secret | Check app logs | No auth errors |
```

Each criterion is:

- Observable (can check status or logs)
- Binary (either passes or fails)
- Objective (anyone can verify)

---

## 6.5 Test Category Example

**Well-Formed Test Categories:**

```markdown
## Test Categories

### Smoke Tests

| Aspect | Description |
|--------|-------------|
| Purpose | Verify basic secret sync works |
| Scope | Single secret from Vault to Kubernetes |
| Environment | Any cluster with Vault access |
| Acceptance | Secret syncs within 60 seconds |

### Integration Tests

| Aspect | Description |
|--------|-------------|
| Purpose | Verify end-to-end application access |
| Scope | Application authenticates using synced secret |
| Environment | Staging cluster |
| Acceptance | Application successfully authenticates to database |

### Failure Tests

| Aspect | Description |
|--------|-------------|
| Purpose | Verify graceful degradation |
| Scope | Vault unavailable, secret rotation, network partition |
| Environment | Chaos testing environment |
| Acceptance | Application continues with cached credentials |
```

---

## 6.6 Risk Documentation Example

**Well-Formed Risk Table:**

```markdown
## Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Vault unavailable during sync | Medium | Medium | ESO retries with backoff; cached secrets remain |
| R2 | Secret rotation causes app failure | Low | High | Graceful reload mechanism in applications |
| R3 | Misconfigured SecretStore | Medium | High | Validation checks before deployment |
| R4 | Secret data exposed in logs | Low | Critical | Audit logging excludes secret values |

## Caveats

| Caveat | Description |
|--------|-------------|
| Sync Delay | Secrets may take up to 60 seconds to sync after Vault update |
| No Push | ESO polls; changes are not pushed immediately |
| Single Vault | This spec assumes single Vault instance |

## Loopholes

| Loophole | Description | Addressed By |
|----------|-------------|--------------|
| Direct Secret Creation | Someone could create Kubernetes Secret directly | RBAC restricts secret creation |
| Secret Caching | App may cache stale secrets | Application reload on SIGHUP |
```

---

*End of Section 6 — RFC-RFCSTD-0003*
