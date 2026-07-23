## Why
The platform needs a baseline Kafka cluster for event streaming. Strimzi is already deployed, but there is no GitOps-managed `Kafka` custom resource that defines the actual broker/Zookeeper cluster. This leads to ad-hoc/manual provisioning and makes scaling/operations inconsistent.

## What Changes
- Add a GitOps-managed Strimzi `Kafka` cluster in the `data-streaming` stack using **KRaft mode** and `KafkaNodePool` resources (ZooKeeper mode was removed in Strimzi 0.46+).
- Provide sensible “average” defaults (3 brokers + 3 controllers, persistent storage, replication factors) that are safe to scale up later.
- Keep the cluster internal-only by default (no external listeners), so it can be consumed from in-cluster workloads immediately.

## Impact
- New stateful workloads will be created (Kafka + Zookeeper) along with PVCs in the chosen namespace.
- ArgoCD will own the Kafka cluster resource and reconcile drift automatically.
- Scaling later becomes a values change (replicas, resources, storage), not a manual procedure.
