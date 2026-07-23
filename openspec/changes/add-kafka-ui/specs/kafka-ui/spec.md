## ADDED Requirements

### Requirement: Kafka UI Deployment
The system SHALL provide a GitOps-managed Kafka UI application for developers to inspect Kafka topics, consumer groups, and message payloads.

#### Scenario: Kafka UI is deployed
- **WHEN** the `data-streaming` stack is synced by ArgoCD
- **THEN** the Kafka UI Deployment and Service exist in the configured namespace

### Requirement: Kafka Cluster Connectivity
The Kafka UI application SHALL connect to the in-cluster Kafka bootstrap service for the `pn-kafka` cluster.

#### Scenario: Kafka UI can reach Kafka
- **WHEN** the Kafka UI application starts
- **THEN** it can list topics from `pn-kafka` via the configured bootstrap server

### Requirement: Optional External Access
The system SHALL support optionally exposing the Kafka UI via ingress with TLS.

#### Scenario: Kafka UI exposed via ingress
- **WHEN** ingress is enabled in values
- **THEN** an Ingress is created and uses a TLS secret issued by cert-manager
