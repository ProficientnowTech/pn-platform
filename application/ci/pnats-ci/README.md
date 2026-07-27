# pn-argo-ci

Argo CI/CD infrastructure chart for the pnow-ats-v2 monorepo. Deploys all resources needed to run PR validation and post-merge build pipelines on Argo Workflows, triggered by GitHub webhooks via Argo Events.

## Architecture

```
GitHub Webhook → Ingress → EventSource → NATS JetStream EventBus → Sensor
                                                                      │
                                              PR opened/synchronize ──┤──→ pr-validation WorkflowTemplate
                                              PR merged to develop ───┤──→ post-merge-build WorkflowTemplate
                                              PR merged to main ──────┘──→ post-merge-build WorkflowTemplate
```

### PR Validation Pipeline

A ContainerSet (single pod on RWO block PVC) runs sequential steps:
1. Report pending status to GitHub
2. Git clone/fetch via HTTPS + PAT (warm PVC: fetch in seconds, cold: full clone)
3. pnpm install (cached on PVC, hard links on block storage)
4. generate-argo-dag.mjs: `nx affected` produces a child workflow YAML with lint/test/build tasks
5. Submit child workflow (dynamic DAG, dependency-ordered per Nx project graph)
6. Report success/failure to GitHub

### Post-Merge Build Pipeline

Same ContainerSet pattern, plus:
1. Build shared libraries (publishable @pnats/* packages)
2. Publish to Verdaccio (`pnpm publish -r`)
3. Rewrite workspace:* refs to real versions
4. Tar workspace and upload as S3 artifact
5. Kaniko fan-out: parallel Docker builds per affected service (each pod downloads S3 artifact)
6. GitOps update: commit image tags to pn-infra → ArgoCD deploys
7. Slack notification

## Components

### Event Infrastructure
| Template | Resource | Purpose |
|----------|----------|---------|
| eventbus.yaml | EventBus | NATS JetStream (3 replicas, persistent) — message bus between EventSource and Sensors |
| eventsource.yaml | EventSource | GitHub webhook receiver — auto-creates webhooks via API token |
| sensor.yaml | Sensor | Routes PR events to pr-validation, merge events to post-merge-build |
| ingress.yaml | Ingress | Exposes EventSource at ci-webhooks.pnats.cloud with TLS |

### Workflow Templates
| Template | Resource | Purpose |
|----------|----------|---------|
| workflow-pr-validation.yaml | WorkflowTemplate | PR validation: lint, test, build via Nx DAG |
| workflow-post-merge-build.yaml | WorkflowTemplate | Post-merge: build, publish, Docker, GitOps, notify |

### Nx Remote Cache
| Template | Resource | Purpose |
|----------|----------|---------|
| nx-cache-server-deployment.yaml | Deployment | Self-hosted Nx cache server (S3-backed, MIT licensed) |
| nx-cache-server-service.yaml | Service | ClusterIP on port 3000 |
| obc-nx-cache.yaml | ObjectBucketClaim | S3 bucket via Rook-Ceph (auto-creates Secret + ConfigMap) |

### Secrets (Generate-Push-Pull Pattern)

The nx-cache-server auth token uses the Generate-Push-Pull bootstrap pattern — a random token is generated once, pushed to Vault, then all consumers pull from Vault as the source of truth.

| Template | Resource | Sync Wave | Purpose |
|----------|----------|-----------|---------|
| nx-cache-server-token-generator.yaml | Password | — | ESO Password generator (64-char alphanumeric) |
| nx-cache-server-token-generated.yaml | ExternalSecret | -6 | Materializes generated token as K8s Secret (one-time) |
| nx-cache-server-token-push.yaml | PushSecret | -5 | Seeds token into Vault at applications/ci/nx-cache-server |
| nx-cache-server-token.yaml | ExternalSecret | -4 | Pulls token from Vault (source of truth, 1h refresh) |

### Other Secrets
| Template | Resource | Purpose |
|----------|----------|---------|
| externalsecrets.yaml | ExternalSecret (loop) | CI credentials from Vault: GitHub token, Harbor auth, Slack webhook |
| externalsecret-verdaccio.yaml | ExternalSecret | Verdaccio auth token (base64 templated from robot credentials in Vault) |

### RBAC
| Template | Resource | Purpose |
|----------|----------|---------|
| sa-ci-workflow.yaml | ServiceAccount | Workflow pod identity with Harbor imagePullSecrets |
| sa-argo-events.yaml | ServiceAccount | Sensor pod identity in argo-events namespace |
| clusterrole-ci-workflow.yaml | ClusterRole | Permissions for emissary executor + workflow management |
| clusterrolebinding-ci-workflow.yaml | ClusterRoleBinding | Binds role to ci-workflow SA |
| clusterrolebinding-argo-events.yaml | ClusterRoleBinding | Binds role to argo-events-sa (cross-namespace) |

### Vault (Crossplane-managed)
| Template | Resource | Purpose |
|----------|----------|---------|
| vault-policy.yaml | Policy | Vault policy for applications/ci/* path access |
| vault-auth-role.yaml | AuthBackendRole | Kubernetes auth role for ci-workflow SA |

### Storage
| Template | Resource | Purpose |
|----------|----------|---------|
| pvc.yaml | PersistentVolumeClaim | RWO block storage workspace (persists git clone, pnpm store, Nx cache) |

## Values

### Required Configuration

```yaml
github:
  owner: ProficientnowTech    # GitHub org/user
  repo: pnow-ats-v2           # Repository name

ciImage: registry.pnats.cloud/pnats/ci-tools:latest
```

### Storage

```yaml
workspace:
  storageClassName: app-blk-hdd-repl  # RWO block storage (NOT CephFS)
  size: 20Gi
  accessMode: ReadWriteOnce

nxCache:
  enabled: true
  storageClassName: app-obj-s3        # Rook-Ceph S3
  maxObjects: "100000"
  maxSize: 10G
```

### Nx Cache Server

```yaml
nxCacheServer:
  enabled: true
  image: ghcr.io/ikatsuba/nx-cache-server:latest
  s3Endpoint: "http://rook-ceph-rgw-app-objectstore.ceph-cluster.svc:80"
  s3Region: "ap-south-2"
```

### Verdaccio

```yaml
verdaccio:
  enabled: true
  vaultPath: applications/developer-platform/verdaccio/app  # PushSecret source
```

### Secrets

Secrets are managed via ExternalSecrets pulling from Vault. Each entry in `secrets:` creates an ExternalSecret:

```yaml
secrets:
  githubToken:
    enabled: true
    refreshInterval: 15m
    target: github-token
    data:
      - secretKey: token
        remoteRef:
          key: applications/ci/github
          property: token
```

## Prerequisites

- Argo Workflows controller running in the cluster
- Argo Events controller running in the cluster
- Rook-Ceph with app-obj-s3 StorageClass and app-blk-hdd-repl StorageClass
- Vault with External Secrets Operator and ClusterSecretStore `vault-backend`
- Harbor registry with ci-tools image pushed
- Vault secrets provisioned at applications/ci/github (token, secret, ssh-privatekey, app-id, installation-id, app-private-key)

## PVC Immutability Note

The workspace PVC spec (storageClassName, accessMode) is immutable. If changing from CephFS to block storage, the old PVC must be manually deleted before ArgoCD can recreate it:

```
kubectl delete pvc ci-workspace -n argo
```

## Related

- **RFC-CICD-0001**: Architecture RFC in the rfcs repo (content/docs/platform/cicd/)
- **pnow-ats-v2 tools/ci/**: DAG generator (generate-argo-dag.mjs), service config (service-config.mjs), workspace ref rewriter (rewrite-workspace-refs.mjs)
- **nx-cache-server**: Forked at ProficientnowTech/nx-cache-server
