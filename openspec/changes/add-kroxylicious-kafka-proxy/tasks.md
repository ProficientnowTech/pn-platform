## 1. Kroxylicious Operator (GitOps)
- [x] 1.1 Add a Helm chart to install Kroxylicious CRDs + operator controller.
- [x] 1.2 Wire the operator chart into `platform/stacks/data-streaming/target-chart/values-production.yaml` with an early sync wave.
- [x] 1.3 Add Argo `ignoreDifferences` for Kroxylicious CRDs `/status` and other noisy metadata fields if needed.

## 2. Kafka Proxy (Single External Bootstrap)
- [x] 2.1 Add a Helm chart that creates `KafkaProxy`, `KafkaService`, `KafkaProxyIngress` (`loadBalancer`), and `VirtualKafkaCluster` for `pn-kafka`.
- [x] 2.2 Configure proxy ingress addresses:
  - `bootstrapAddress`: `kafka.pnats.cloud`
  - `advertisedBrokerAddressPattern`: `broker-$(nodeId).kafka.pnats.cloud` (supports wildcard DNS)
- [x] 2.3 Configure TLS secret reference for the load balancer ingress (certificate must cover bootstrap + wildcard broker names).

## 3. Strimzi External Listener
- [x] 3.1 Disable Strimzi per-broker external `loadBalancer` listener in `platform/stacks/data-streaming/charts/kafka-cluster/values.yaml`.

## 4. Validation
- [x] 4.1 `helm lint` / `helm template` all changed/new charts.
- [x] 4.2 Confirm rendered resources reference correct namespaces and backend bootstrap service.
