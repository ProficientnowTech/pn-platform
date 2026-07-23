# Developer Portal Capability

## ADDED Requirements

### Requirement: Backstage Deployment
The platform SHALL provide Backstage as a developer portal for self-service infrastructure provisioning.

#### Scenario: Deploy Backstage
- **WHEN** Backstage chart is deployed
- **THEN** Backstage pods are running
- **AND** Backstage UI is accessible
- **AND** SQLite backend is initialized

#### Scenario: Authenticate with Keycloak
- **WHEN** Backstage is configured with Keycloak auth provider
- **THEN** users can sign in via Keycloak SSO
- **AND** user information is available in Backstage

### Requirement: Cluster Provisioning Template
The platform SHALL provide a software template for provisioning Kubernetes clusters.

#### Scenario: Create cluster template
- **WHEN** cluster provisioning template is registered
- **THEN** template appears in Backstage catalog
- **AND** users can see template parameters

#### Scenario: Provision cluster via template
- **WHEN** a user fills in cluster parameters and submits
- **THEN** Backstage creates a GitHub PR with Crossplane claim
- **AND** PR contains cluster specification YAML
- **AND** user receives PR link

#### Scenario: Merge triggers provisioning
- **WHEN** the PR is merged
- **THEN** ArgoCD syncs the Crossplane claim
- **AND** Crossplane provisions the cluster
- **AND** cluster becomes available

### Requirement: Database Provisioning Template
The platform SHALL provide a software template for provisioning PostgreSQL databases.

#### Scenario: Create database template
- **WHEN** database provisioning template is registered
- **THEN** template appears in Backstage catalog
- **AND** users can select environment and size

#### Scenario: Provision database via template
- **WHEN** a user submits database request
- **THEN** Backstage creates PR with PostgreSQLInstance claim
- **AND** PR is linked to requesting user

#### Scenario: Database becomes available
- **WHEN** database PR is merged
- **THEN** Crossplane provisions the database
- **AND** credentials are stored in Vault
- **AND** database is ready for application use

### Requirement: GitHub Integration
The platform SHALL integrate Backstage with GitHub for PR creation and repository management.

#### Scenario: Configure GitHub App
- **WHEN** Backstage is configured with GitHub credentials
- **THEN** Backstage can create PRs in pn-infra repository
- **AND** Backstage can read repository structure

#### Scenario: Template creates valid PR
- **WHEN** a software template is executed
- **THEN** PR is created with valid YAML manifests
- **AND** PR description includes parameter summary
- **AND** PR is assigned to correct branch

### Requirement: Resource Catalog
The platform SHALL display provisioned infrastructure resources in Backstage catalog.

#### Scenario: View clusters
- **WHEN** a user navigates to infrastructure catalog
- **THEN** provisioned clusters are listed
- **AND** cluster status is shown (ready, pending, failed)

#### Scenario: View databases
- **WHEN** a user views database catalog
- **THEN** provisioned databases are listed
- **AND** database connection information is available
