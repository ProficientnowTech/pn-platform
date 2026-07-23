# Identity and Access Management Capability

## ADDED Requirements

### Requirement: Keycloak Identity Provider
The platform SHALL provide Keycloak for centralized authentication and SSO.

#### Scenario: Deploy Keycloak
- **WHEN** Keycloak chart is deployed
- **THEN** Keycloak pods are running
- **AND** Keycloak admin console is accessible
- **AND** PostgreSQL backend is connected

#### Scenario: Create platform realm
- **WHEN** platform realm is created in Keycloak
- **THEN** realm is active and available
- **AND** OIDC endpoints are accessible

### Requirement: OIDC Integration for ArgoCD
The platform SHALL integrate ArgoCD with Keycloak for SSO authentication.

#### Scenario: Configure ArgoCD OIDC
- **WHEN** ArgoCD ConfigMap is updated with Keycloak OIDC settings
- **THEN** ArgoCD shows SSO login option
- **AND** users can login via Keycloak

#### Scenario: User logs in to ArgoCD
- **WHEN** a user clicks "Login via Keycloak"
- **THEN** user is redirected to Keycloak login
- **AND** after authentication, user is redirected back to ArgoCD
- **AND** user has access based on RBAC policy

### Requirement: OIDC Integration for Backstage
The platform SHALL integrate Backstage with Keycloak for SSO authentication.

#### Scenario: Configure Backstage OIDC
- **WHEN** Backstage is deployed with Keycloak auth provider
- **THEN** Backstage shows Keycloak login button
- **AND** users can authenticate

#### Scenario: User logs in to Backstage
- **WHEN** a user clicks "Sign in with Keycloak"
- **THEN** user authenticates via Keycloak
- **AND** user session is established in Backstage
- **AND** user can access software templates

### Requirement: OIDC Integration for Kargo
The platform SHALL integrate Kargo with Keycloak for SSO authentication.

#### Scenario: Configure Kargo OIDC
- **WHEN** Kargo is deployed with Keycloak OIDC settings
- **THEN** Kargo UI shows SSO login
- **AND** users can authenticate via Keycloak

#### Scenario: User manages promotions
- **WHEN** an authenticated user accesses Kargo UI
- **THEN** user can view stages and promotions
- **AND** user can trigger promotions based on permissions

### Requirement: Client Configuration
The platform SHALL maintain OIDC client configurations for all integrated services.

#### Scenario: Create ArgoCD client
- **WHEN** ArgoCD OIDC client is created in Keycloak
- **THEN** client ID and secret are generated
- **AND** redirect URIs are configured
- **AND** client secret is stored in Vault

#### Scenario: Create Backstage client
- **WHEN** Backstage OIDC client is created
- **THEN** client configuration supports authorization code flow
- **AND** scopes include profile and email
- **AND** client secret is stored in Vault
