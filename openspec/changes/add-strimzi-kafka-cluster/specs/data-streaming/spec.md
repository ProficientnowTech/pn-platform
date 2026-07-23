## ADDED Requirements

### Requirement: GitOps-Managed Kafka Cluster (Strimzi, KRaft Mode)
The `data-streaming` stack MUST deploy a Strimzi `Kafka` cluster via ArgoCD using KRaft mode and `KafkaNodePool` resources so the platform has a baseline event-streaming service that can be scaled via GitOps changes.

#### Scenario: Baseline cluster install
- **WHEN** the `data-streaming` stack is synced
- **THEN** a Strimzi `Kafka` resource and its corresponding `KafkaNodePool` resources are applied for the baseline cluster
- **AND** Kafka brokers and controllers converge to Ready without manual steps.

#### Scenario: Scale brokers and ZooKeeper via values
- **WHEN** operators update the chart values (e.g., `kafka.replicas`, `zookeeper.replicas`)
- **THEN** ArgoCD reconciles the `Kafka` resource
- **AND** Strimzi performs the rolling changes to reach the new replica counts.

#### Scenario: Safe defaults for durability
- **WHEN** the baseline cluster is deployed
- **THEN** it MUST use replication defaults suitable for 3 brokers (e.g., RF=3, min ISR=2 for critical internal topics)
- **AND** it MUST use persistent storage for both Kafka and ZooKeeper so data survives restarts.
