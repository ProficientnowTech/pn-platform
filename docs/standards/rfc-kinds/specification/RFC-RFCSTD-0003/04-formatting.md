```
RFC-RFCSTD-0003                                                   Section 4
Category: Standards Track                           Formatting Standards
```

# 4. Formatting Standards

[← Structure](./03-structure.md) | [Index](./00-index.md) | [Next →](./05-validation.md)

---

## 4.1 Document Header

Each file in a Specification RFC MUST begin with:

```
```
RFC-SPEC-<DOMAIN>-NNNN                                            Section N
Category: Specification                                     <Section Title>
```

# N. Section Title

[← Previous](./prev.md) | [Index](./00-index.md) | [Next →](./next.md)

---
```

---

## 4.2 Prerequisite Format

Prerequisites MUST be formatted as tables:

```markdown
## Infrastructure Prerequisites

| Prerequisite | Type | Version | Verification |
|--------------|------|---------|--------------|
| Kubernetes cluster | Required | 1.28+ | `kubectl version` shows 1.28+ |
| Helm | Required | 3.12+ | `helm version` shows 3.12+ |
| Network access to registry | Required | N/A | Can pull test image |
```

Types:

| Type | Meaning |
|------|---------|
| Required | Implementation fails without this |
| Optional | Implementation works but with reduced functionality |
| Conditional | Required only if specific feature is enabled |

---

## 4.3 Phase Format

Phases MUST follow the task → test → iterate structure:

```markdown
## Phase 2: Configure Identity Provider

### Tasks

| Task | Description | Outcome |
|------|-------------|---------|
| 2.1 | Create namespace | Namespace exists |
| 2.2 | Deploy Keycloak | Keycloak pods running |
| 2.3 | Configure realm | Realm accessible |

### Test

| Verification | Method | Expected Result |
|--------------|--------|-----------------|
| Keycloak accessible | Access admin console | Login page displays |
| Realm exists | Check realm list | Platform realm present |

### Iterate

| Checkpoint | Proceed If | Rollback If |
|------------|------------|-------------|
| All verifications pass | Continue to Phase 3 | Execute Phase 2 Rollback |

### Rollback

| Step | Action |
|------|--------|
| 2.R1 | Delete realm |
| 2.R2 | Delete Keycloak deployment |
| 2.R3 | Delete namespace |
```

---

## 4.4 Resource Table Format

Resources MUST be defined in tables, not code:

```markdown
## Kubernetes Resources

| Resource | Type | Namespace | Purpose | Dependencies |
|----------|------|-----------|---------|--------------|
| keycloak-config | ConfigMap | identity | Keycloak configuration | Namespace |
| keycloak-admin | Secret | identity | Admin credentials | Namespace, Vault |
| keycloak | StatefulSet | identity | Keycloak deployment | ConfigMap, Secret |
```

**NOT permitted:**

```yaml
# This is NOT permitted in Specification RFCs
apiVersion: v1
kind: ConfigMap
metadata:
  name: keycloak-config
```

---

## 4.5 Validation Criteria Format

Validation criteria MUST be tabular and deterministic:

```markdown
## Validation Criteria

| ID | Criterion | Method | Pass Condition |
|----|-----------|--------|----------------|
| V1 | Keycloak accessible | HTTP GET /health | Returns 200 |
| V2 | Admin login works | Login with admin creds | Session created |
| V3 | Realm configured | Check realm settings | All settings match spec |
```

---

## 4.6 Test Category Format

Test requirements MUST be organized by category:

```markdown
## Test Categories

### Integration Tests

| Aspect | Description |
|--------|-------------|
| Purpose | Verify component interactions |
| Scope | Keycloak ↔ Vault ↔ Applications |
| Environment | Staging cluster |
| Acceptance | All integration tests pass |

### Smoke Tests

| Aspect | Description |
|--------|-------------|
| Purpose | Verify basic functionality |
| Scope | Login, token generation, logout |
| Environment | Any environment |
| Acceptance | All smoke tests pass within 5 minutes |
```

---

## 4.7 Risk Format

Risks MUST be documented with likelihood, impact, and mitigation:

```markdown
## Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Keycloak unavailable during deployment | Medium | High | Rolling update strategy |
| R2 | Secret rotation fails | Low | High | Manual rotation procedure documented |
| R3 | Network partition isolates Keycloak | Low | High | Multi-zone deployment |
```

---

## 4.8 Navigation and Footer

Same as other RFC kinds:

- Navigation links after header
- Footer with RFC identifier at end

---

*End of Section 4 — RFC-RFCSTD-0003*
