## 1. Kafka Cluster Chart
- [x] 1.1 Create a new Helm chart under `platform/stacks/data-streaming/charts/kafka-cluster/` that renders a Strimzi `Kafka` resource (Zookeeper mode).
- [x] 1.2 Add values for: `kafka.replicas`, `zookeeper.replicas`, storage sizes, resource requests/limits, and key Kafka defaults (replication factor / min ISR / partitions / retention).
- [x] 1.3 Enable Strimzi `entityOperator` (topic + user operators) for future GitOps-managed topics/users.

## 2. Wire Into Stack
- [x] 2.1 Add a new ArgoCD Application entry in `platform/stacks/data-streaming/target-chart/values-production.yaml` for the Kafka cluster chart.
- [x] 2.2 Add `ignoreDifferences` for the `Kafka` CR `/status` to avoid OutOfSync noise.
- [x] 2.3 Choose namespace placement (default: `strimzi-kafka-operator` to match current operator watch scope).

## 3. Validation
- [x] 3.1 `helm template` the new chart(s) and ensure manifests render with the intended names/labels.
- [x] 3.2 `kubectl apply --dry-run=server` for the rendered manifests to validate against live CRDs.
- [ ] 3.3 Confirm the resulting Strimzi resources are created (Kafka + Zookeeper) and become Ready in the target namespace.
