## Why
Developers need a self-serve UI to inspect Kafka topics, consumer groups, and message payloads without requiring direct broker access or ad-hoc tooling.

## What Changes
- Add a GitOps-managed Kafka UI application in the `data-streaming` stack.
- Configure the UI to connect to the in-cluster Strimzi bootstrap service (`pn-kafka-kafka-bootstrap.strimzi-kafka-operator.svc:9092`).
- Optionally expose the UI via `ingress-nginx` with `external-dns` + `cert-manager` TLS (defaults to enabled).

## Impact
- Affected systems: ArgoCD (new Application), ingress-nginx (new Ingress), external-dns (new DNS record), cert-manager (new Certificate secret).
- Security: UI must be access-controlled (either internal-only or protected ingress). Initial implementation will include an allowlist option; OIDC can be added later if required.

## Assumptions / Open Questions
- Tool choice: Kafbat UI (https://kafbat.io / https://ui.docs.kafbat.io), deployed from `ghcr.io/kafbat/kafka-ui`.
- External hostname: default `kafka-ui.pnats.cloud` (can be changed in values).
