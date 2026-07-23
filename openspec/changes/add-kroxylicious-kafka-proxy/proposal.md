## Why
Strimzi `Kafka` external access via per-broker `LoadBalancer` Services consumes one IP per broker, which does not fit our constrained MetalLB address pool. We need a single external bootstrap endpoint for developers (KafkaJS/Python clients) while keeping broker connectivity correct and scalable.

## What Changes
- Deploy the Kroxylicious Operator (OSS, Apache 2.0) to manage Kafka protocol proxy instances.
- Create a `KafkaProxy`, `KafkaService`, `KafkaProxyIngress` (`loadBalancer`), and `VirtualKafkaCluster` so external clients can connect via one bootstrap hostname while the proxy rewrites broker addresses using SNI and wildcard DNS.
- Enable a baseline audit capability by attaching the Kroxylicious `SaslInspection` protocol filter to the virtual cluster (logs SASL authentication events and exposes authenticated principals to future filters).
- Disable Strimzi per-broker external `LoadBalancer` listener in the `kafka-cluster` chart (brokers remain internal; proxy provides the external entrypoint).

## Impact
- Adds a new operator (CRDs + controller Deployment) and new proxy runtime pods.
- Requires DNS for `kafka.pnats.cloud` and wildcard broker names (e.g. `*.kafka.pnats.cloud`) to resolve to the proxy `LoadBalancer` external address.
- Requires a TLS server certificate Secret in the proxy namespace covering the bootstrap + wildcard broker hostnames.
