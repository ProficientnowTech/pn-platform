## 1. Implementation
- [x] 1.1 Add Helm chart `platform/stacks/data-streaming/charts/kafka-ui` for Kafbat UI (Deployment, Service, optional Ingress)
- [x] 1.2 Configure Kafka connection to `pn-kafka-kafka-bootstrap.strimzi-kafka-operator.svc.cluster.local:9092`
- [x] 1.3 Add ingress + TLS + external-dns values (hostname default `kafka-ui.pnats.cloud`)
- [x] 1.4 Wire chart into `platform/stacks/data-streaming/target-chart/values-production.yaml` with an appropriate sync-wave

## 2. Validation
- [x] 2.1 `helm template` renders cleanly
- [ ] 2.2 ArgoCD sync creates UI resources in target namespace
- [ ] 2.3 UI loads and can list topics/consume messages from `pn-kafka`

## 3. Follow-ups (optional)
- [ ] 3.1 Add Keycloak OIDC support (SSO) if required
