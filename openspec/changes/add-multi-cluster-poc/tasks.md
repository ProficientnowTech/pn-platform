# Implementation Tasks

## 1. Foundation Infrastructure

### 1.1 Storage and Network Prerequisites
- [ ] 1.1.1 Verify CephFS ReadWriteMany storage is available
- [ ] 1.1.2 Configure MetalLB IP pool for workload clusters (e.g., 192.168.107.50-192.168.107.70)
- [ ] 1.1.3 Plan DNS strategy (*.dev.pnats.cloud for dev cluster)

## 2. Vault Secret Management

### 2.1 Deploy Vault
- [ ] 2.1.1 Create `v0.2.0/platform/charts/vault/values.yaml`
- [ ] 2.1.2 Configure Vault HA (3 replicas) with Raft storage
- [ ] 2.1.3 Add to target-chart at sync wave 300
- [ ] 2.1.4 Deploy via ArgoCD

### 2.2 Initialize Vault
- [ ] 2.2.1 Run `vault operator init` and save unseal keys
- [ ] 2.2.2 Unseal all replicas
- [ ] 2.2.3 Enable Kubernetes auth: `vault auth enable kubernetes`
- [ ] 2.2.4 Create secret paths: `secret/clusters/*`, `secret/database/*`
- [ ] 2.2.5 Create basic policies for access

### 2.3 Deploy External Secrets Operator
- [ ] 2.3.1 Create `v0.2.0/platform/charts/external-secrets/values.yaml`
- [ ] 2.3.2 Add to target-chart at sync wave 310
- [ ] 2.3.3 Create ClusterSecretStore pointing to Vault
- [ ] 2.3.4 Test with a simple ExternalSecret

## 3. Keycloak Identity

### 3.1 Deploy Keycloak
- [ ] 3.1.1 Create `v0.2.0/platform/charts/keycloak/values.yaml`
- [ ] 3.1.2 Configure with embedded PostgreSQL (simple for PoC)
- [ ] 3.1.3 Configure ingress (keycloak.pnats.cloud)
- [ ] 3.1.4 Add to target-chart at sync wave 320
- [ ] 3.1.5 Deploy via ArgoCD

### 3.2 Configure Keycloak
- [ ] 3.2.1 Login to Keycloak admin console
- [ ] 3.2.2 Create "platform" realm
- [ ] 3.2.3 Create "argocd" OIDC client
- [ ] 3.2.4 Create "backstage" OIDC client
- [ ] 3.2.5 Create test user account

### 3.3 Integrate ArgoCD with Keycloak
- [ ] 3.3.1 Update ArgoCD ConfigMap with OIDC settings
- [ ] 3.3.2 Configure RBAC for Keycloak users
- [ ] 3.3.3 Test SSO login to ArgoCD

## 4. Network and Virtualization

### 4.1 Deploy Kube-OVN
- [ ] 4.1.1 Create `v0.2.0/platform/charts/kube-ovn/values.yaml`
- [ ] 4.1.2 Configure Kube-OVN for overlay network
- [ ] 4.1.3 Enable persistent pod IPs for VMs
- [ ] 4.1.4 Add to target-chart at sync wave 330
- [ ] 4.1.5 Verify Kube-OVN pods are running

### 4.2 Deploy KubeVirt
- [ ] 4.2.1 Create `v0.2.0/platform/charts/kubevirt/values.yaml`
- [ ] 4.2.2 Add CDI for VM disk management
- [ ] 4.2.3 Configure live migration support
- [ ] 4.2.4 Add to target-chart at sync wave 340
- [ ] 4.2.5 Verify KubeVirt operator is ready

### 4.3 Deploy ClusterAPI
- [ ] 4.3.1 Create `v0.2.0/platform/charts/clusterapi/values.yaml`
- [ ] 4.3.2 Install ClusterAPI core + KubeVirt provider
- [ ] 4.3.3 Add to target-chart at sync wave 350
- [ ] 4.3.4 Verify ClusterAPI CRDs are registered

## 5. Crossplane

### 5.1 Deploy Crossplane
- [ ] 5.1.1 Create `v0.2.0/platform/charts/crossplane/values.yaml`
- [ ] 5.1.2 Add to target-chart at sync wave 360
- [ ] 5.1.3 Deploy via ArgoCD

### 5.2 Install Providers
- [ ] 5.2.1 Install provider-kubernetes
- [ ] 5.2.2 Install provider-helm
- [ ] 5.2.3 Configure ProviderConfigs
- [ ] 5.2.4 Verify providers are healthy

### 5.3 Create Cluster XRD
- [ ] 5.3.1 Create `v0.2.0/platform/apps/crossplane-config/cluster-xrd.yaml`
- [ ] 5.3.2 Create `v0.2.0/platform/apps/crossplane-config/cluster-composition.yaml`
- [ ] 5.3.3 Include live migration support in composition
- [ ] 5.3.4 Add to target-chart at sync wave 410
- [ ] 5.3.5 Apply and verify CRD registration

## 6. Progressive Delivery

### 6.1 Deploy Kargo
- [ ] 6.1.1 Create `v0.2.0/platform/charts/kargo/values.yaml`
- [ ] 6.1.2 Configure Kargo API and controller
- [ ] 6.1.3 Configure Kargo UI ingress (kargo.pnats.cloud)
- [ ] 6.1.4 Add to target-chart at sync wave 370
- [ ] 6.1.5 Verify Kargo is running and accessible

### 6.2 Deploy Argo Rollouts
- [ ] 6.2.1 Create `v0.2.0/platform/charts/argo-rollouts/values.yaml`
- [ ] 6.2.2 Configure Argo Rollouts controller
- [ ] 6.2.3 Add to target-chart at sync wave 380
- [ ] 6.2.4 Verify Argo Rollouts controller is ready

### 6.3 Configure Kargo Integration
- [ ] 6.3.1 Create Kargo Project for demo app
- [ ] 6.3.2 Define stages: dev → (future: staging → production)
- [ ] 6.3.3 Configure promotion policies
- [ ] 6.3.4 Test manual promotion workflow

## 7. Provision Dev Cluster

### 7.1 Create Cluster Claim
- [ ] 7.1.1 Create `v0.2.0/platform/apps/dev-cluster/cluster.yaml`
- [ ] 7.1.2 Request: 1 control plane (2 CPU, 4Gi), 2 workers (2 CPU, 4Gi, 50Gi)
- [ ] 7.1.3 Enable Kube-OVN CNI and live migration
- [ ] 7.1.4 Add to target-chart at sync wave 420
- [ ] 7.1.5 Apply and monitor ClusterAPI provisioning

### 7.2 Access Dev Cluster
- [ ] 7.2.1 Wait for cluster to be ready (check ClusterAPI status)
- [ ] 7.2.2 Get kubeconfig: `kubectl get secret dev-kubeconfig -o jsonpath='{.data.value}' | base64 -d`
- [ ] 7.2.3 Test access: `kubectl --kubeconfig=dev.kubeconfig get nodes`
- [ ] 7.2.4 Store kubeconfig in Vault at `secret/clusters/dev/kubeconfig`

### 7.3 Configure Dev Cluster
- [ ] 7.3.1 Deploy Kube-OVN to dev cluster
- [ ] 7.3.2 Deploy ingress-nginx to dev cluster
- [ ] 7.3.3 Deploy cert-manager to dev cluster
- [ ] 7.3.4 Deploy external-dns to dev cluster
- [ ] 7.3.5 Deploy ESO to dev cluster
- [ ] 7.3.6 Deploy Argo Rollouts to dev cluster
- [ ] 7.3.7 Configure Vault auth for dev cluster
- [ ] 7.3.8 Register dev cluster in ArgoCD and Kargo

## 8. Backstage

### 8.1 Deploy Backstage
- [ ] 8.1.1 Create `v0.2.0/platform/charts/backstage/values.yaml`
- [ ] 8.1.2 Configure with SQLite (simple for PoC)
- [ ] 8.1.3 Configure Keycloak OIDC auth
- [ ] 8.1.4 Configure GitHub integration
- [ ] 8.1.5 Add to target-chart at sync wave 390
- [ ] 8.1.6 Deploy and verify access

### 8.2 Create Software Templates
- [ ] 8.2.1 Create cluster provisioning template
- [ ] 8.2.2 Create database provisioning template
- [ ] 8.2.3 Templates create PRs with Crossplane claims
- [ ] 8.2.4 Test template workflows

## 9. Demo Application

### 9.1 Deploy Shared PostgreSQL
- [ ] 9.1.1 Create `v0.2.0/platform/charts/postgres-shared/values.yaml`
- [ ] 9.1.2 Deploy in primary cluster at sync wave 400
- [ ] 9.1.3 Create dev database
- [ ] 9.1.4 Store credentials in Vault

### 9.2 Create Demo App with Rollout
- [ ] 9.2.1 Create simple app (nginx + backend connecting to PostgreSQL)
- [ ] 9.2.2 Configure Rollout resource (canary strategy)
- [ ] 9.2.3 Configure ExternalSecret for DB credentials
- [ ] 9.2.4 Configure Ingress (demo.dev.pnats.cloud)
- [ ] 9.2.5 Configure Kargo Stage for dev

### 9.3 Deploy Demo App
- [ ] 9.3.1 Deploy via ArgoCD to dev cluster
- [ ] 9.3.2 Verify app can access shared PostgreSQL
- [ ] 9.3.3 Test canary rollout with Argo Rollouts
- [ ] 9.3.4 Test Kargo promotion workflow

## 10. Testing and Validation

### 10.1 Core Functionality
- [ ] 10.1.1 Verify dev cluster is fully functional
- [ ] 10.1.2 Test VM live migration (migrate control plane VM)
- [ ] 10.1.3 Verify cluster remains available during migration
- [ ] 10.1.4 Verify Vault distributes secrets to dev cluster
- [ ] 10.1.5 Verify Keycloak SSO works for ArgoCD, Backstage, and Kargo
- [ ] 10.1.6 Verify demo app accesses shared PostgreSQL
- [ ] 10.1.7 Verify Backstage templates create valid PRs

### 10.2 Progressive Delivery
- [ ] 10.2.1 Test canary deployment with Argo Rollouts
- [ ] 10.2.2 Test Kargo stage promotion
- [ ] 10.2.3 Verify rollback functionality
- [ ] 10.2.4 Test automated promotion policies

### 10.3 GitOps Validation
- [ ] 10.3.1 Verify all components managed by ArgoCD
- [ ] 10.3.2 Test sync and self-heal
- [ ] 10.3.3 Verify sync waves execute correctly

## 11. Documentation

### 11.1 Essential Docs
- [ ] 11.1.1 Update architecture diagrams with actual setup
- [ ] 11.1.2 Document Vault unsealing procedure
- [ ] 11.1.3 Document VM live migration testing
- [ ] 11.1.4 Document how to access dev cluster
- [ ] 11.1.5 Document Kargo promotion workflows
- [ ] 11.1.6 Document how to use Backstage templates
- [ ] 11.1.7 Create troubleshooting guide

### 11.2 Demo
- [ ] 11.2.1 Create demo walkthrough script
- [ ] 11.2.2 Test complete end-to-end flow
- [ ] 11.2.3 Document known limitations
- [ ] 11.2.4 Record demo video showing all capabilities
