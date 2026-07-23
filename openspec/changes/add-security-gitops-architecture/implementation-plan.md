# Complete Auth Flow Implementation Plan

## Executive Summary

This document outlines the complete authentication and authorization flow for the PN Platform using a **Vault-first, GitOps-managed** security architecture. The implementation leverages AzureAD as the primary identity provider for all users (developers and admins), with selective OTP/2FA enforcement based on application sensitivity.

## Current State Assessment

### ✅ Completed Infrastructure

#### 1. Secret Management Layer
- **Vault**: Deployed with HA (3 replicas), auto-initialization, auto-unsealing
- **External Secrets Operator**: Deployed and configured to sync from Vault
- **Vault Integration**: Templates for ExternalSecrets, PushSecrets, SecretStore

#### 2. Crossplane Providers (All Installed)
- provider-kubernetes (v0.14.0)
- provider-helm (v0.19.0)
- provider-vault (v0.8.0)
- provider-argocd (v0.7.0)
- **provider-azuread** (v1.4.1) - Currently disabled, needs activation
- provider-keycloak (v0.5.0)
- provider-kafka (v0.5.0)
- provider-temporal (v1.5.0)
- provider-ovh (v2.9.1)
- provider-grafana (v0.40.0)
- provider-harbor (v3.11.2)
- provider-postgresql (v0.1.0)
- provider-proxmox-bpg (v0.11.1)

#### 3. Keycloak Identity Platform
**Deployed Components:**
- Keycloak (v26.0.7) with PostgreSQL backend (HA ready with 2 replicas + HPA)
- Realm: `pcp` (ProficientNow Cloud Platform)
- Identity Providers:
  - GitHub OAuth (configured)
  - AzureAD OIDC (configured)

**OIDC Clients (All Configured):**
- argocd
- grafana
- backstage
- oneuptime
- harbor
- verdaccio-oauth (via oauth2-proxy)
- kargo
- tekton-dashboard
- argo-rollouts
- temporal-ui
- kubevirt-manager

**Groups Configured:**
- platform-admins
- platform-developers
- platform-viewers
- harbor-registry-a-push/read
- verdaccio-publishers/readers
- kargo-admins/users
- tekton-operators
- argo-rollouts-operators

#### 4. Policy & Runtime Security
- **Kyverno**: Deployed with baseline policies
- **Falco**: Deployed with eBPF driver + falcosidekick
- **Falco Talon**: Deployed for action routing

## Updated Auth Flow Design

### Design Decision Changes

**Per user requirements:**
1. ✅ **AzureAD for All Users**: Both developers and admins use AzureAD SSO (no GitHub IdP for developers)
2. ✅ **Selective OTP**: Not all applications require mandatory OTP/2FA
   - **OTP Required**: ArgoCD, Grafana, Harbor, Keycloak Admin Console
   - **OTP Optional**: Backstage, Temporal UI, KubeVirt Manager, Kargo, Tekton Dashboard, Argo Rollouts, OneUptime, Verdaccio

### Authentication Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Authentication Flow                │
└─────────────────────────────────────────────────────────────┘

1. User accesses application (e.g., argocd.pnats.cloud)
   ↓
2. Application redirects to Keycloak
   ↓
3. Keycloak presents IdP choice: AzureAD
   ↓
4. User authenticates with AzureAD (Microsoft credentials)
   ↓
5. AzureAD returns to Keycloak with user info
   ↓
6. [Conditional] If app requires OTP:
   ├─ Keycloak prompts for TOTP code
   └─ User enters 6-digit code from authenticator app
   ↓
7. Keycloak issues tokens (id_token, access_token, refresh_token)
   ↓
8. Application receives tokens and grants access
   ↓
9. User accesses application with assigned roles/groups

┌─────────────────────────────────────────────────────────────┐
│                Service Account Authentication               │
└─────────────────────────────────────────────────────────────┘

1. Service sends client_id + client_secret to Keycloak
   ↓
2. Keycloak validates credentials
   ↓
3. Issues access_token with service account roles
   ↓
4. Service uses token for API calls
```

## Implementation Tasks

### AzureAD Integration

#### Task 1.1: Enable AzureAD Provider in Crossplane
**File**: `platform/stacks/security/charts/crossplane/values.yaml`

```yaml
providerConfig:
  azuread:
    enabled: true  # Change from false to true
    tenantId: "your-tenant-id"
    clientId: "crossplane-service-principal-client-id"
    clientSecretSecretName: "azuread-crossplane-credentials"
    clientSecretSecretKey: "client-secret"
```

**Prerequisites:**
- Create Azure AD App Registration for Crossplane
- Grant permissions: `Application.ReadWrite.All`, `Directory.Read.All`
- Create service principal
- Store credentials in Vault at `secret/crossplane/providers/azuread`

#### Task 1.2: Configure Keycloak AzureAD IdP Settings
**Status**: Already configured in `platform/stacks/security/charts/keycloak/values.yaml`

**Verify Configuration:**
- AzureAD tenant: proficientnowtech.onmicrosoft.com
- Client ID: cd877378-420e-46b7-8cc4-82d58bc1022d
- Client secret: Sourced from `azuread-keycloak-oidc-credentials` (Vault-backed)
- Scopes: `openid profile email`
- Token claims mapping: email → email, name → name, groups → groups

#### Task 1.3: Remove/Disable GitHub IdP
Since developers now use AzureAD:

**File**: `platform/stacks/security/charts/keycloak/values.yaml`

```yaml
identityProviders:
- alias: github
  enabled: false  # Disable GitHub IdP
  # ... rest of config

- alias: azuread
  enabled: true  # Keep AzureAD enabled
  # ... rest of config
```

#### Task 1.4: Update First Broker Login Flow
Configure post-authentication actions after AzureAD login:

1. Create ExternalSecret for Keycloak admin credentials
2. Access Keycloak admin console
3. Configure "First Broker Login" flow:
   - Review Profile (on first login)
   - Create User if Missing
   - Map AzureAD groups to Keycloak roles

### OTP/2FA Configuration

#### Task 2.1: Define OTP Policy per Application

**High Security (OTP Required):**
- ArgoCD (infrastructure control)
- Grafana (observability/monitoring data)
- Harbor (container registry, supply chain)
- Keycloak Admin Console (identity management)

**Standard Security (OTP Optional):**
- Backstage (developer portal)
- Temporal UI (workflow visibility)
- KubeVirt Manager (VM management)
- Kargo (GitOps release management)
- Tekton Dashboard (CI/CD pipelines)
- Argo Rollouts (progressive delivery)
- OneUptime (incident management)
- Verdaccio (npm registry)

#### Task 2.2: Configure Authentication Flows

**Create Custom Flows:**

1. **Browser Flow - High Security** (for OTP-required apps)
   ```
   Browser
   └─ Cookie
   └─ Identity Provider Redirector (AzureAD)
   └─ OTP Form (REQUIRED)
   ```

2. **Browser Flow - Standard Security** (for OTP-optional apps)
   ```
   Browser
   └─ Cookie
   └─ Identity Provider Redirector (AzureAD)
   └─ OTP Form (CONDITIONAL - user can skip if not enrolled)
   ```

3. **Direct Grant Flow** (for CLI/API access)
   ```
   Direct Grant
   └─ Username/Password
   └─ OTP (CONDITIONAL on client)
   ```

4. **Service Account Flow** (for machine-to-machine)
   ```
   Client Credentials
   └─ Client ID + Secret validation
   └─ No user interaction
   ```

#### Task 2.3: Assign Flows to Clients

**Update Keycloak client configurations:**

```yaml
# Example for ArgoCD (OTP required)
clients:
- name: argocd
  clientId: argocd
  browserFlow: browser-high-security  # Custom flow
  directGrantFlow: direct-grant-otp   # OTP required for CLI

# Example for Backstage (OTP optional)
- name: backstage
  clientId: backstage
  browserFlow: browser-standard-security  # Standard flow
  directGrantFlow: direct-grant            # No OTP for API
```

#### Task 2.4: Configure OTP Settings

**Keycloak Realm Settings:**
- OTP Policy: TOTP (Time-based)
- Algorithm: HmacSHA256
- Digits: 6
- Period: 30 seconds
- Initial Counter: 0
- Supported Apps: Google Authenticator, Microsoft Authenticator, Authy

### Application Integration

#### Task 3.1: Update Application OIDC Configurations

##### ArgoCD
**File**: `platform/stacks/infrastructure/charts/argocd/values.yaml`

```yaml
argocd:
  configs:
    cm:
      url: https://argocd.pnats.cloud
      oidc.config: |
        name: Keycloak
        issuer: https://keycloak.pnats.cloud/realms/pcp
        clientID: argocd
        clientSecret: $oidc.keycloak.clientSecret
        requestedScopes: ["openid", "profile", "email", "groups"]
        requestedIDTokenClaims:
          groups:
            essential: true
    rbac:
      policy.csv: |
        p, role:admin, applications, *, */*, allow
        p, role:admin, clusters, get, *, allow
        p, role:admin, repositories, *, *, allow
        g, platform-admins, role:admin
        g, platform-developers, role:readonly
```

##### Grafana
**File**: `platform/stacks/monitoring/charts/grafana/values.yaml`

```yaml
grafana:
  grafana.ini:
    auth.generic_oauth:
      enabled: true
      name: Keycloak
      allow_sign_up: true
      client_id: grafana
      client_secret: $__file{/etc/secrets/grafana-oidc/client-secret}
      scopes: openid email profile groups
      email_attribute_path: email
      login_attribute_path: preferred_username
      name_attribute_path: name
      auth_url: https://keycloak.pnats.cloud/realms/pcp/protocol/openid-connect/auth
      token_url: https://keycloak.pnats.cloud/realms/pcp/protocol/openid-connect/token
      api_url: https://keycloak.pnats.cloud/realms/pcp/protocol/openid-connect/userinfo
      role_attribute_path: contains(groups[*], 'platform-admins') && 'Admin' || contains(groups[*], 'platform-developers') && 'Editor' || 'Viewer'
```

##### Backstage
**File**: `platform/stacks/developer-platform/charts/backstage/values.yaml`

```yaml
backstage:
  appConfig:
    auth:
      environment: production
      providers:
        oidc:
          production:
            metadataUrl: https://keycloak.pnats.cloud/realms/pcp/.well-known/openid-configuration
            clientId: backstage
            clientSecret: ${OIDC_CLIENT_SECRET}
            prompt: auto
            signIn:
              resolvers:
                - resolver: emailMatchingUserEntityProfileEmail
```

##### Harbor (via oauth2-proxy)
**File**: `platform/stacks/developer-platform/charts/harbor/values.yaml`

```yaml
oauth2-proxy:
  enabled: true
  config:
    provider: keycloak-oidc
    oidcIssuerUrl: https://keycloak.pnats.cloud/realms/pcp
    clientID: harbor
    clientSecret: ${OIDC_CLIENT_SECRET}
    emailDomains:
      - "*"
    scope: openid email profile groups
    redirectUrl: https://harbor.pnats.cloud/oauth2/callback
```

##### Verdaccio (via oauth2-proxy)
**File**: `platform/stacks/developer-platform/charts/verdaccio/values.yaml`

```yaml
oauth2-proxy:
  enabled: true
  config:
    provider: keycloak-oidc
    oidcIssuerUrl: https://keycloak.pnats.cloud/realms/pcp
    clientID: verdaccio-oauth
    clientSecret: ${OIDC_CLIENT_SECRET}
    emailDomains:
      - "*"
    upstreamFilters:
      - "^verdaccio-publishers$"
      - "^verdaccio-readers$"
```

##### Kargo
**File**: `platform/stacks/development-workloads/charts/kargo/values.yaml`

```yaml
api:
  oidc:
    enabled: true
    issuerURL: https://keycloak.pnats.cloud/realms/pcp
    clientID: kargo
    clientSecret: ${OIDC_CLIENT_SECRET}
    groupsClaim: groups
```

##### Tekton Dashboard
**File**: `platform/stacks/developer-platform/charts/tekton-dashboard/values.yaml`

```yaml
dashboard:
  oidc:
    enabled: true
    provider: keycloak
    issuerURL: https://keycloak.pnats.cloud/realms/pcp
    clientID: tekton-dashboard
    clientSecret: ${OIDC_CLIENT_SECRET}
```

##### Argo Rollouts
**File**: `platform/stacks/development-workloads/charts/argo-rollouts/values.yaml`

```yaml
dashboard:
  oidc:
    enabled: true
    issuerURL: https://keycloak.pnats.cloud/realms/pcp
    clientID: argo-rollouts
    clientSecret: ${OIDC_CLIENT_SECRET}
```

##### OneUptime
**File**: `platform/stacks/monitoring/charts/oneuptime/values.yaml`

```yaml
oneuptime:
  sso:
    enabled: true
    provider: oidc
    issuerUrl: https://keycloak.pnats.cloud/realms/pcp
    clientId: oneuptime
    clientSecret: ${OIDC_CLIENT_SECRET}
```

##### Temporal UI
**File**: `platform/stacks/application-infra/charts/temporal/values.yaml`

```yaml
web:
  config:
    auth:
      enabled: true
      providers:
        - label: Keycloak
          type: oidc
          issuer: https://keycloak.pnats.cloud/realms/pcp
          client_id: temporal-ui
          client_secret: ${OIDC_CLIENT_SECRET}
```

##### KubeVirt Manager
**File**: `platform/stacks/developer-platform/charts/kubevirt-manager/values.yaml`

```yaml
kubevirt-manager:
  auth:
    oidc:
      enabled: true
      issuerURL: https://keycloak.pnats.cloud/realms/pcp
      clientID: kubevirt-manager
      clientSecret: ${OIDC_CLIENT_SECRET}
```

### Secret Management

#### Task 4.1: Create Vault Secret Structure

```bash
# Keycloak admin credentials
vault kv put secret/applications/security/keycloak/admin \
  admin-password="<secure-password>"

# Keycloak PostgreSQL credentials
vault kv put secret/applications/security/keycloak/postgres \
  postgres-password="<secure-password>" \
  password="<secure-password>"

# Keycloak Crossplane provider credentials
vault kv put secret/applications/security/keycloak/provider \
  username="admin" \
  password="<admin-password>"

# AzureAD IdP credentials
vault kv put secret/applications/security/idp/azuread \
  client-id="cd877378-420e-46b7-8cc4-82d58bc1022d" \
  client-secret="<azure-app-secret>"

# OIDC Client Secrets (for each application)
vault kv put secret/applications/security/keycloak/clients/argocd \
  client-secret="<generated-secret>"

vault kv put secret/applications/security/keycloak/clients/grafana \
  client-secret="<generated-secret>"

# ... repeat for all clients
```

#### Task 4.2: Create ExternalSecrets for Each Application

**Example for ArgoCD:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argocd-oidc-secret
  namespace: argocd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: argocd-oidc-secret
    creationPolicy: Owner
  data:
  - secretKey: client-secret
    remoteRef:
      key: secret/applications/security/keycloak/clients/argocd
      property: client-secret
```

### Testing & Validation

#### Task 5.1: End-to-End Testing Checklist

**For Each Application:**
1. [ ] Access application URL (e.g., https://argocd.pnats.cloud)
2. [ ] Verify redirect to Keycloak
3. [ ] Verify AzureAD login flow
4. [ ] [If OTP Required] Verify OTP prompt appears
5. [ ] Verify successful authentication
6. [ ] Verify correct role/group assignment
7. [ ] Verify authorization (can access allowed resources)
8. [ ] Verify token refresh works
9. [ ] Verify logout works

**CLI/API Testing:**
1. [ ] Test ArgoCD CLI with `argocd login --sso`
2. [ ] Test kubectl with OIDC (if configured)
3. [ ] Test service account authentication

#### Task 5.2: Security Validation

1. [ ] Verify HTTPS/TLS for all IdP callbacks
2. [ ] Verify no credentials in Git
3. [ ] Verify secrets are in Vault
4. [ ] Verify ExternalSecrets are syncing
5. [ ] Test OTP enforcement (try to bypass)
6. [ ] Test session timeout
7. [ ] Test concurrent sessions
8. [ ] Verify Falco alerts on suspicious auth patterns
9. [ ] Verify Kyverno policies enforce security

### Documentation & Runbooks

#### Task 6.1: User Documentation

Create docs for:
1. **User Onboarding Guide**
   - How to access platform applications
   - Setting up OTP/2FA (Google Authenticator setup)
   - Troubleshooting common login issues

2. **Developer Guide**
   - CLI authentication with OIDC
   - Service account usage
   - API token management

3. **Admin Guide**
   - Managing users and groups in AzureAD
   - Keycloak administration
   - Adding new applications to SSO

#### Task 6.2: Operational Runbooks

Create runbooks for:
1. **Incident Response**
   - User locked out (failed OTP attempts)
   - Keycloak service down
   - AzureAD connectivity issues
   - Token validation failures

2. **Maintenance Operations**
   - Rotating client secrets
   - Updating IdP configuration
   - Adding new OIDC clients
   - Modifying authentication flows

3. **Monitoring & Alerts**
   - Authentication success/failure rates
   - Token expiration/refresh patterns
   - OTP enrollment rates
   - Suspicious login patterns

## ArgoCD Sync Wave Ordering

Ensure proper dependency ordering:

```yaml
# security-stack/values-production.yaml
applications:
- name: vault
  annotations:
    argocd.argoproj.io/sync-wave: "-20"

- name: external-secrets
  annotations:
    argocd.argoproj.io/sync-wave: "-15"

- name: crossplane
  annotations:
    argocd.argoproj.io/sync-wave: "-10"

- name: keycloak
  annotations:
    argocd.argoproj.io/sync-wave: "0"

- name: kyverno
  annotations:
    argocd.argoproj.io/sync-wave: "10"

- name: falco
  annotations:
    argocd.argoproj.io/sync-wave: "15"

- name: falco-talon
  annotations:
    argocd.argoproj.io/sync-wave: "16"
```

## Success Criteria

### Functional Requirements
- ✅ All users authenticate via AzureAD SSO
- ✅ High-security apps (ArgoCD, Grafana, Harbor, Keycloak Admin) require OTP
- ✅ Standard apps allow OTP-optional login
- ✅ Service accounts use client credentials (no user interaction)
- ✅ All secrets managed through Vault → ExternalSecrets
- ✅ No credentials stored in Git
- ✅ All applications integrate with Keycloak OIDC

### Non-Functional Requirements
- ✅ Login latency < 3 seconds (excluding user input time)
- ✅ Token refresh transparent to users
- ✅ Session timeout configurable per application
- ✅ Audit logs for all authentication events
- ✅ 99.9% availability for auth services

### Security Requirements
- ✅ TLS 1.2+ for all connections
- ✅ Secrets encrypted at rest (Vault)
- ✅ Secrets encrypted in transit (TLS)
- ✅ Password policy enforced (12+ chars, complexity)
- ✅ Brute force protection enabled
- ✅ Session fixation protection
- ✅ CSRF protection on all forms
- ✅ Security headers configured (HSTS, CSP, etc.)

## Risk Mitigation

### Risk: Keycloak Single Point of Failure
**Mitigation:**
- HA deployment (2+ replicas with HPA)
- PostgreSQL with persistent storage
- Health checks and auto-recovery
- Backup/restore procedures

### Risk: AzureAD Outage
**Mitigation:**
- Cache authenticated sessions (configurable timeout)
- Emergency admin access via local Keycloak users
- Monitor AzureAD service health

### Risk: OTP Device Loss
**Mitigation:**
- Recovery codes generated during OTP enrollment
- Admin can reset OTP requirement
- Document recovery procedures

### Risk: Secret Leakage
**Mitigation:**
- GitHub push protection enabled
- Pre-commit hooks to scan for secrets
- Vault audit logging
- Regular secret rotation

### Network Observability (NetObserv)

#### Overview

NetObserv provides Calico-compatible network observability using eBPF-based flow collection, processing, and storage. It captures network flows at the kernel level without requiring Cilium, making it suitable for Calico deployments.

#### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   NetObserv Architecture                    │
└─────────────────────────────────────────────────────────────┘

Kubernetes Nodes (with Calico CNI)
├─ eBPF Agents (DaemonSet)
│  ├─ Capture network packets at kernel level
│  ├─ Extract flow metadata (5-tuple, K8s labels)
│  ├─ Apply sampling (1 in 50 packets)
│  └─ Send flows to flowlogs-pipeline
│
├─ FlowLogs Pipeline (Deployment + HPA)
│  ├─ Receive flows from eBPF agents (IPFIX/NetFlow format)
│  ├─ Enrich with Kubernetes metadata
│  │  └─ Pod names, namespaces, labels, owner references
│  ├─ Process and aggregate flows
│  └─ Export to storage backends:
│     ├─ Loki (flow logs)
│     └─ Prometheus (metrics)
│
├─ Storage & Observability
│  ├─ Loki: Store flow logs with labels
│  │  └─ Query with LogQL
│  ├─ Prometheus: Store flow metrics
│  │  └─ namespace_flows_total
│  │  └─ workload_ingress_bytes_total
│  │  └─ workload_egress_bytes_total
│  │  └─ node_ingress_bytes_total
│  └─ Grafana: Visualize flows and metrics
```

#### Components Deployed

**NetObserv Operator**:
- Manages lifecycle of flow collection components
- Watches FlowCollector CRD
- Deploys and configures eBPF agents and flowlogs-pipeline

**FlowCollector CR**:
- Configuration for flow collection
- Agent settings (eBPF, sampling rate)
- Processor settings (replicas, HPA)
- Export settings (Loki, Prometheus)

**eBPF Agents (DaemonSet)**:
- Image: `quay.io/netobserv/netobserv-ebpf-agent:v1.7.0`
- Runs on all nodes
- Privileged mode (required for eBPF)
- Sampling: 1 in 50 packets
- Features: PacketDrop, DNSTracking, FlowRTT
- Excludes: lo interface

**FlowLogs Pipeline (Deployment)**:
- Image: `quay.io/netobserv/flowlogs-pipeline:v1.7.0`
- 2-5 replicas (HPA based on CPU/memory)
- Enriches flows with K8s metadata
- Exports to Loki and Prometheus

#### Configuration Highlights

**platform/stacks/security/charts/netobserv/values.yaml**:

```yaml
flowCollector:
  agent:
    type: eBPF
    ebpf:
      sampling: 50  # Sample 1 in 50 packets
      features:
        - PacketDrop
        - DNSTracking
        - FlowRTT

  processor:
    replicas: 2
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5

  loki:
    enable: true
    url: "http://loki-gateway.monitoring.svc.cluster.local:80/loki/api/v1/push"
    tenantID: "netobserv"

  prometheus:
    enable: true
    metrics:
      - name: namespace_flows_total
      - name: workload_ingress_bytes_total
      - name: workload_egress_bytes_total
```

#### Integration with Monitoring Stack

NetObserv requires the monitoring stack (Loki, Prometheus, Grafana) to be deployed:

1. **Loki**: Stores flow logs
   - URL: `http://loki-gateway.monitoring.svc.cluster.local:80/loki/api/v1/push`
   - Tenant: `netobserv`

2. **Prometheus**: Scrapes flow metrics
   - ServiceMonitor enabled for operator metrics
   - Flow metrics exported by flowlogs-pipeline

3. **Grafana**: Visualizes flows
   - Dashboard for flow analytics
   - LogQL queries for flow logs
   - PromQL queries for metrics

#### ArgoCD Configuration

**Sync Wave**: 50 (after Falco/Falco-Talon)

**Sync Options**:
- `CreateNamespace=true`
- `ServerSideApply=true`

**Ignore Differences**:
- CRD webhook caBundle (auto-generated by cert-manager)
- DaemonSet resources (adjusted by VPA/HPA)

#### Use Cases

1. **Network Policy Troubleshooting**
   - Identify blocked flows due to Calico NetworkPolicies
   - Analyze packet drops

2. **Service Communication Mapping**
   - Visualize service-to-service communication
   - Identify unexpected traffic patterns

3. **Performance Analysis**
   - Measure flow RTT (round-trip time)
   - Identify high-bandwidth workloads

4. **Security Monitoring**
   - Detect anomalous network behavior
   - Track DNS queries (potential data exfiltration)
   - Integrate with Falco for correlation

#### Validation

**Check eBPF Agents Running**:
```bash
kubectl get daemonset -n netobserv
kubectl get pods -n netobserv -l app=netobserv-ebpf-agent
```

**Check FlowLogs Pipeline**:
```bash
kubectl get deployment -n netobserv
kubectl get pods -n netobserv -l app=flowlogs-pipeline
```

**Check FlowCollector Status**:
```bash
kubectl get flowcollector cluster -o yaml
```

**Query Flow Logs in Loki**:
```logql
{job="flowlogs-pipeline"}
```

**Query Flow Metrics in Prometheus**:
```promql
namespace_flows_total
workload_ingress_bytes_total{namespace="default"}
```

#### Performance Tuning

**Sampling Rate**:
- Current: 1 in 50 packets
- Increase for less load: 1 in 100
- Decrease for more accuracy: 1 in 10

**Agent Resources**:
- Current: 100m CPU, 50Mi memory (requests)
- Scale up for high-traffic nodes

**Processor Replicas**:
- HPA: 2-5 replicas based on CPU/memory
- Adjust for cluster size and flow volume

## Next Steps

1. Enable AzureAD Crossplane provider (Task 1.1)
2. Disable GitHub IdP (Task 1.3)
3. Configure OTP flows and authentication flows
4. Update application OIDC configurations
5. Configure secret management and ExternalSecrets
6. Perform end-to-end testing and security validation
7. Create documentation and operational runbooks
