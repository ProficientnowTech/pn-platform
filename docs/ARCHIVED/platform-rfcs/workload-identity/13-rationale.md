```
RFC-WORKLOAD-IDENTITY-0001                                     Section 13
Category: Standards Track                                      Rationale
```

# 13. Rationale

[← Previous: Federation](./12-federation.md) | [Index](./00-index.md#table-of-contents) | [Next: Evolution →](./14-evolution.md)

---

## 13.1 Why SPIFFE/SPIRE

### 13.1.1 Selection Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Standards-based | High | Industry-standard specification |
| Multi-platform | High | Works across clouds and on-prem |
| Attestation-based | High | No pre-shared secrets |
| Kubernetes-native | Medium | First-class K8s support |
| Federation ready | Medium | Multi-cluster capability |
| Open source | Medium | No vendor lock-in |
| Active community | Medium | Long-term viability |

### 13.1.2 SPIFFE/SPIRE Strengths

| Strength | Benefit |
|----------|---------|
| **CNCF Graduated** | Proven, stable, well-maintained |
| **Attestation model** | Proves workload identity without secrets |
| **X.509 and JWT SVIDs** | Flexible identity formats |
| **Federated by design** | Multi-cluster from the start |
| **Vault integration** | SPIFFE auth method available |
| **Service mesh compatible** | Linkerd, Istio, Envoy support |

### 13.1.3 SPIFFE/SPIRE Considerations

| Consideration | Mitigation |
|---------------|------------|
| Operational complexity | Phased rollout, training |
| Additional infrastructure | Start with Kubernetes-native, add SPIRE later |
| Learning curve | Documentation, examples |
| SPIRE server as dependency | HA deployment, fallback patterns |

---

## 13.2 Alternative Identity Frameworks

### 13.2.1 Kubernetes Native Only

**Description**: Use only Kubernetes ServiceAccounts and projected tokens.

**Why It Was Attractive**:
- No additional infrastructure
- Built into Kubernetes
- Simple mental model
- Works with Vault Kubernetes auth

**Why It Was Not Sufficient**:
- Limited to Kubernetes only
- No cross-cluster federation
- No attestation beyond pod metadata
- No standard identity format
- Service mesh requires additional identity

**Conclusion**: Kubernetes-native is a foundation, not a complete solution. SPIRE builds on it.

### 13.2.2 HashiCorp Vault Only

**Description**: Use Vault as the sole identity provider.

**Why It Was Attractive**:
- Already using Vault for secrets
- AppRole, Kubernetes auth methods
- Single system to manage
- Good audit logging

**Why It Was Not Sufficient**:
- Vault is credential authority, not identity issuer
- No workload attestation
- Not designed for service-to-service mTLS
- Doesn't integrate with service mesh
- SPIFFE auth method still needs SPIRE

**Conclusion**: Vault complements SPIFFE as credential authority, but doesn't replace it for identity.

### 13.2.3 Istio Service Mesh

**Description**: Use Istio's built-in identity (Citadel).

**Why It Was Attractive**:
- Comprehensive service mesh
- Built-in identity and mTLS
- Rich traffic management
- Well-documented

**Why It Was Not Chosen**:
- Heavier than Linkerd (Envoy-based)
- More complex configuration
- Higher resource overhead
- Linkerd better fits lightweight requirements

**Conclusion**: Istio is valid but Linkerd chosen for simplicity. Both support SPIFFE.

### 13.2.4 Cloud-Only Solutions

**Description**: Use only cloud provider identity (IRSA, Workload Identity).

**Why It Was Attractive**:
- Native to cloud provider
- No additional components
- Well-integrated with cloud services
- Managed by cloud provider

**Why It Was Not Sufficient**:
- Cloud-specific, not portable
- Different patterns per cloud
- No on-premises support
- No cross-cloud federation standard
- Service mesh still needs identity

**Conclusion**: Cloud identity is used for cloud resources, but SPIFFE provides unified layer.

---

## 13.3 Why Linkerd for Service Mesh

### 13.3.1 Service Mesh Comparison

| Feature | Linkerd | Istio | Cilium |
|---------|---------|-------|--------|
| **Proxy** | Rust (linkerd2-proxy) | Envoy (C++) | eBPF (no sidecar) |
| **Resource overhead** | Low | Medium-High | Very low |
| **Configuration complexity** | Low | High | Medium |
| **mTLS** | Automatic | Configurable | Automatic |
| **SPIRE integration** | Optional | Optional | Limited |
| **Learning curve** | Gentle | Steep | Medium |

### 13.3.2 Why Linkerd

| Reason | Explanation |
|--------|-------------|
| **Lightweight** | Rust proxy uses less CPU/memory than Envoy |
| **Simple** | Fewer configuration options, less to get wrong |
| **Automatic mTLS** | Works out of the box |
| **SPIRE compatible** | Can integrate when needed |
| **CNCF Graduated** | Production-ready, well-maintained |

### 13.3.3 Linkerd Considerations

| Consideration | Mitigation |
|---------------|------------|
| Less feature-rich than Istio | Sufficient for mTLS and authz needs |
| Smaller community than Istio | Active development, responsive maintainers |
| No built-in Wasm support | Not required for current use cases |

---

## 13.4 Why OAuth 2.0 Token Exchange for AI Agents

### 13.4.1 AI Agent Identity Alternatives

| Alternative | Issue |
|-------------|-------|
| **Static API keys** | No delegation tracking, long-lived |
| **Service accounts** | Agent identity, not delegator |
| **OAuth client credentials** | Same as service accounts |
| **Custom tokens** | Non-standard, maintenance burden |

### 13.4.2 Token Exchange Advantages

| Advantage | Description |
|-----------|-------------|
| **Standard** | RFC 8693, widely supported |
| **Delegation chain** | `act` claim preserves who delegated |
| **Scope attenuation** | Each exchange can reduce scope |
| **Keycloak support** | Built-in Token Exchange |
| **Auditable** | Standard claims for logging |

### 13.4.3 Token Exchange Considerations

| Consideration | Mitigation |
|---------------|------------|
| Keycloak configuration | Document setup process |
| Chain complexity | Limit maximum chain depth |
| Token size | Chain in claims grows token size |

---

## 13.5 Why Separate from RFC-PAM

### 13.5.1 Fundamental Differences

| Aspect | RFC-PAM (Human) | RFC-WORKLOAD-IDENTITY (Machine) |
|--------|-----------------|--------------------------------|
| **Principal type** | Human users | Workloads, services, agents |
| **Authentication** | Interactive (OIDC, MFA) | Programmatic (certificates, tokens) |
| **Session concept** | Recorded interactive session | Connection or request |
| **Access pattern** | JIT, approval-based | Pre-authorized, policy-based |
| **Recording** | Mandatory | Optional (per policy) |
| **Credential flow** | Human → Teleport → Vault | Workload → Vault directly |

### 13.5.2 Why Not Combine

| Argument for combining | Counter-argument |
|------------------------|------------------|
| "Both are access management" | Different principals, different patterns |
| "Same infrastructure" | Share Vault, but different auth paths |
| "Simpler to have one RFC" | Cleaner to separate concerns |

### 13.5.3 Shared Components

| Component | PAM Usage | Workload Identity Usage |
|-----------|-----------|-------------------------|
| **Vault** | SSH certs, DB creds via Teleport | Direct creds via K8s auth |
| **Keycloak** | Human SSO | AI agent delegation |
| **Azure AD** | Authorization ceiling | Authorization ceiling |
| **Teleport** | Human access broker | Machine ID for VMs |

---

## 13.6 Architecture Decision Records

### ADR-WI-001: SPIFFE/SPIRE as Primary Identity Framework

**Status**: Accepted

**Context**: Need unified workload identity across Kubernetes, VMs, and multi-cloud.

**Decision**: Use SPIFFE specification with SPIRE implementation as primary workload identity framework.

**Consequences**:
- Portable, standards-based identity
- Attestation-based security model
- Additional infrastructure to manage
- Training required for teams

### ADR-WI-002: Linkerd for Service Mesh Identity

**Status**: Accepted

**Context**: Need mTLS and service-to-service authorization.

**Decision**: Use Linkerd for service mesh with optional SPIRE integration.

**Consequences**:
- Lightweight, automatic mTLS
- Simple authorization policies
- Less feature-rich than Istio
- Sufficient for current needs

### ADR-WI-003: OAuth 2.0 Token Exchange for AI Agents

**Status**: Accepted

**Context**: AI agents need to act on behalf of humans with accountability.

**Decision**: Use RFC 8693 Token Exchange for delegation.

**Consequences**:
- Standards-based delegation
- Full chain visibility
- Keycloak configuration needed
- May need to limit chain depth

### ADR-WI-004: Vault Kubernetes Auth as Primary

**Status**: Accepted

**Context**: Kubernetes workloads need Vault access without static credentials.

**Decision**: Use Vault Kubernetes auth method with projected ServiceAccount tokens.

**Consequences**:
- No static credentials in cluster
- Namespace-scoped policies possible
- Vault becomes dependency
- Token refresh needed

### ADR-WI-005: Teleport Machine ID for VMs

**Status**: Accepted

**Context**: Non-Kubernetes machines need identity for automation.

**Decision**: Use Teleport Machine ID (tbot) for VM identity.

**Consequences**:
- Consistent identity for VMs
- Integrates with existing Teleport
- Requires Teleport infrastructure
- Cloud attestation support

---

## 13.7 Trade-off Summary

| Decision | Trade-off | Rationale |
|----------|-----------|-----------|
| SPIFFE over custom | Complexity vs standards | Standards enable ecosystem |
| Linkerd over Istio | Features vs simplicity | Simplicity reduces errors |
| Token Exchange over custom | Flexibility vs standards | Standards enable interop |
| Separate from PAM | Consolidation vs clarity | Clarity enables ownership |
| Short-lived creds | Convenience vs security | Security is non-negotiable |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 12. Federation](./12-federation.md) | [Table of Contents](./00-index.md#table-of-contents) | [14. Evolution →](./14-evolution.md) |

---

*End of Section 13 — RFC-WORKLOAD-IDENTITY-0001*
