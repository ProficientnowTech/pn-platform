# Manual Keycloak OTP/2FA Configuration Guide

## Overview

This document outlines the manual steps required to configure custom authentication flows for selective OTP/2FA enforcement in Keycloak. These steps must be performed via the Keycloak admin console as the Crossplane Keycloak provider does not currently support declarative authentication flow management.

## Prerequisites

- Keycloak deployed and accessible at https://keycloak.pnats.cloud
- Admin credentials available from Vault path: `secret/applications/security/keycloak/admin`
- AzureAD IdP configured and enabled
- GitHub IdP disabled
- All OIDC clients configured (ArgoCD, Grafana, Backstage, Harbor, etc.)

## Authentication Flow Strategy

### High Security Applications (OTP Required)
- **ArgoCD**: Infrastructure control plane
- **Grafana**: Observability and monitoring data
- **Harbor**: Container registry (supply chain security)
- **Keycloak Admin Console**: Identity management

### Standard Security Applications (OTP Optional)
- **Backstage**: Developer portal
- **Temporal UI**: Workflow visibility
- **KubeVirt Manager**: VM management
- **Kargo**: GitOps release management
- **Tekton Dashboard**: CI/CD pipelines
- **Argo Rollouts**: Progressive delivery
- **OneUptime**: Incident management
- **Verdaccio**: NPM registry

## Step 1: Access Keycloak Admin Console

1. Navigate to https://keycloak.pnats.cloud/admin
2. Login with admin credentials from Vault
3. Select the `pcp` realm from the realm dropdown

## Step 2: Configure OTP Policy

1. In the left sidebar, navigate to **Authentication** → **Policies** → **OTP Policy**
2. Configure the following settings:

```
OTP Type: Time-based (TOTP)
Algorithm: HmacSHA256
Number of Digits: 6
Look Around Window: 1
OTP Hash Algorithm: SHA256
Token Period: 30 seconds
Supported Applications: Google Authenticator, Microsoft Authenticator, Authy, FreeOTP
Initial Counter: 0
```

3. Click **Save**

## Step 3: Create Custom Authentication Flow - High Security

This flow enforces OTP for high-security applications.

### Create the Flow

1. Navigate to **Authentication** → **Flows**
2. Click **Create** (or use the dropdown → **Duplicate** on existing "browser" flow)
3. Set the following:
   - **Alias**: `browser-high-security`
   - **Description**: `Browser flow with mandatory OTP for high-security applications`
4. Click **Create**

### Configure Flow Steps

After creating the flow, configure the execution steps:

1. **Cookie** (Alternative)
   - Set **Requirement**: ALTERNATIVE

2. **Identity Provider Redirector** (Alternative)
   - Set **Requirement**: ALTERNATIVE
   - Click **Actions** → **Config**
     - **Alias**: `azuread-redirect`
     - **Default Identity Provider**: `azuread`
   - Click **Save**

3. **OTP Form** (Required)
   - Add execution: Click **Add Step** → select **OTP Form**
   - Set **Requirement**: REQUIRED

4. **Conditional OTP** (Conditional - for existing users)
   - Add execution: Click **Add Step** → select **Conditional - User Configured**
   - Set **Requirement**: CONDITIONAL

### Final Flow Structure

```
browser-high-security
├─ Cookie [ALTERNATIVE]
├─ Identity Provider Redirector [ALTERNATIVE]
│  └─ Config: Default IdP = azuread
└─ Forms [ALTERNATIVE]
   ├─ Username Password Form [REQUIRED]
   └─ Conditional OTP [CONDITIONAL]
      └─ Condition - User Configured [REQUIRED]
      └─ OTP Form [REQUIRED]
```

## Step 4: Create Custom Authentication Flow - Standard Security

This flow makes OTP optional for standard applications.

### Create the Flow

1. Navigate to **Authentication** → **Flows**
2. Click **Create**
3. Set the following:
   - **Alias**: `browser-standard-security`
   - **Description**: `Browser flow with optional OTP for standard applications`
4. Click **Create**

### Configure Flow Steps

1. **Cookie** (Alternative)
   - Set **Requirement**: ALTERNATIVE

2. **Identity Provider Redirector** (Alternative)
   - Set **Requirement**: ALTERNATIVE
   - Click **Actions** → **Config**
     - **Alias**: `azuread-redirect-standard`
     - **Default Identity Provider**: `azuread`
   - Click **Save**

3. **Conditional OTP** (Alternative - optional for users)
   - Add execution: Click **Add Step** → select **Conditional - User Configured**
   - Set **Requirement**: ALTERNATIVE

### Final Flow Structure

```
browser-standard-security
├─ Cookie [ALTERNATIVE]
├─ Identity Provider Redirector [ALTERNATIVE]
│  └─ Config: Default IdP = azuread
└─ Forms [ALTERNATIVE]
   ├─ Username Password Form [REQUIRED]
   └─ Conditional OTP [ALTERNATIVE]
      └─ Condition - User Configured [REQUIRED]
      └─ OTP Form [OPTIONAL]
```

## Step 5: Assign Flows to OIDC Clients

### High Security Applications (OTP Required)

For each of these clients, assign the `browser-high-security` flow:

#### ArgoCD
1. Navigate to **Clients** → **argocd**
2. Go to **Advanced** tab → **Authentication Flow Overrides**
3. Set **Browser Flow**: `browser-high-security`
4. Set **Direct Grant Flow**: `direct-grant` (default)
5. Click **Save**

#### Grafana
1. Navigate to **Clients** → **grafana**
2. Go to **Advanced** tab → **Authentication Flow Overrides**
3. Set **Browser Flow**: `browser-high-security`
4. Click **Save**

#### Harbor
1. Navigate to **Clients** → **harbor**
2. Go to **Advanced** tab → **Authentication Flow Overrides**
3. Set **Browser Flow**: `browser-high-security`
4. Click **Save**

### Standard Security Applications (OTP Optional)

For each of these clients, assign the `browser-standard-security` flow:

- backstage
- oneuptime
- verdaccio-oauth
- kargo
- tekton-dashboard
- argo-rollouts
- temporal-ui
- kubevirt-manager

**Steps for each**:
1. Navigate to **Clients** → **{client-name}**
2. Go to **Advanced** tab → **Authentication Flow Overrides**
3. Set **Browser Flow**: `browser-standard-security`
4. Click **Save**

## Step 6: Configure Admin Console OTP

Enforce OTP for Keycloak admin console access:

1. Navigate to **Authentication** → **Flows**
2. Find the **browser** flow (default flow for admin console)
3. Edit the flow to add OTP requirement similar to high-security flow above
4. Or create a dedicated `admin-console` flow and bind it to the master realm

## Step 7: Test Authentication Flows

### Test High-Security App (ArgoCD)

1. Logout of all Keycloak sessions
2. Navigate to https://argocd.pnats.cloud
3. Click login
4. **Expected**: Redirect to Keycloak → AzureAD login
5. Login with AzureAD credentials
6. **Expected**: After AzureAD auth, Keycloak prompts for OTP setup (first time)
7. Scan QR code with authenticator app
8. Enter 6-digit code
9. **Expected**: Redirected back to ArgoCD with successful authentication

### Test Standard-Security App (Backstage)

1. Logout of all Keycloak sessions
2. Navigate to https://backstage.pnats.cloud
3. Click login
4. **Expected**: Redirect to Keycloak → AzureAD login
5. Login with AzureAD credentials
6. **Expected**: After AzureAD auth, redirected back to Backstage (OTP not prompted unless user has it configured)

## Step 8: User Enrollment Process

### For High-Security Apps
Users MUST enroll OTP on their first login to a high-security application:

1. User accesses high-security app (e.g., ArgoCD)
2. Redirected to Keycloak → AzureAD
3. After AzureAD auth, Keycloak presents OTP enrollment screen
4. User scans QR code with authenticator app (Google Authenticator, Microsoft Authenticator, Authy)
5. User enters 6-digit code to verify
6. OTP is now enrolled and required for future logins

### For Standard-Security Apps
Users MAY optionally enroll OTP:

1. User accesses account management: https://keycloak.pnats.cloud/realms/pcp/account
2. Navigate to **Account Security** → **Signing In**
3. Click **Set up Authenticator application**
4. Scan QR code and verify
5. OTP is now enrolled and will be prompted on future logins (but can be skipped)

## Step 9: Recovery Procedures

### User Loses OTP Device

**Admin Steps**:
1. Login to Keycloak admin console
2. Navigate to **Users** → search for user → **Credentials** tab
3. Find **OTP** credential
4. Click **Delete** to remove OTP requirement
5. User can re-enroll on next login

**User Steps**:
1. Contact platform admin to reset OTP
2. On next login, re-enroll OTP device

### Backup Recovery Codes

Consider generating recovery codes for users:

1. Navigate to **Authentication** → **Required Actions**
2. Enable **Configure Recovery Codes**
3. Users will be prompted to generate recovery codes on next login
4. Users should store recovery codes securely (password manager, printed, etc.)

## Step 10: Monitoring and Auditing

### Enable Keycloak Event Logging

1. Navigate to **Realm Settings** → **Events** → **Event Listeners**
2. Add **jboss-logging** to event listeners
3. Navigate to **Login Events Settings**
4. Enable **Save Events**
5. Set **Expiration**: 90 days (or per compliance requirements)
6. Select events to log:
   - Login
   - Login Error
   - Logout
   - Update TOTP
   - Remove TOTP
   - Update Password

### Falco Rules for Suspicious Auth Patterns

Falco will automatically detect:
- Multiple failed OTP attempts
- Unusual login times or locations (if client IP is logged)
- Rapid credential changes
- OTP removal followed by re-enrollment

## Validation Checklist

After completing the manual setup:

- [ ] OTP policy configured with TOTP, 6 digits, 30 second period
- [ ] browser-high-security flow created with REQUIRED OTP
- [ ] browser-standard-security flow created with OPTIONAL OTP
- [ ] ArgoCD client assigned to browser-high-security
- [ ] Grafana client assigned to browser-high-security
- [ ] Harbor client assigned to browser-high-security
- [ ] Backstage client assigned to browser-standard-security
- [ ] Temporal UI client assigned to browser-standard-security
- [ ] KubeVirt Manager client assigned to browser-standard-security
- [ ] Kargo client assigned to browser-standard-security
- [ ] Tekton Dashboard client assigned to browser-standard-security
- [ ] Argo Rollouts client assigned to browser-standard-security
- [ ] OneUptime client assigned to browser-standard-security
- [ ] Verdaccio client assigned to browser-standard-security
- [ ] Admin console OTP enforced
- [ ] Test login to ArgoCD requires OTP
- [ ] Test login to Backstage does not require OTP (unless enrolled)
- [ ] Event logging enabled for audit
- [ ] Recovery procedures documented and shared with team

## Future Automation

Consider contributing to the Crossplane Keycloak provider to add support for:
- `AuthenticationFlow` CRD
- `AuthenticationExecution` CRD
- `AuthenticationConfig` CRD

This would allow full GitOps management of authentication flows without manual console configuration.

## References

- [Keycloak Authentication Documentation](https://www.keycloak.org/docs/latest/server_admin/#authentication-flows)
- [Keycloak OTP Policy](https://www.keycloak.org/docs/latest/server_admin/#otp-policies)
- [Crossplane Provider Keycloak](https://github.com/crossplane-contrib/provider-keycloak)
