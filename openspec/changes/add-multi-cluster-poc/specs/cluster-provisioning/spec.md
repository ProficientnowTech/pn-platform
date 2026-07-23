# Cluster Provisioning Capability

## ADDED Requirements

### Requirement: KubeVirt Virtualization Platform
The platform SHALL provide KubeVirt virtualization capabilities to run virtual machines as Kubernetes resources.

#### Scenario: Deploy KubeVirt operator
- **WHEN** KubeVirt chart is deployed via ArgoCD
- **THEN** KubeVirt operator pods are running in kubevirt namespace
- **AND** VirtualMachine CRDs are registered

#### Scenario: VM creation and lifecycle
- **WHEN** a VirtualMachine resource is created
- **THEN** the VM boots successfully
- **AND** the VM is accessible via its IP address

###Requirement: Kube-OVN Network Plugin
The platform SHALL provide Kube-OVN CNI for advanced networking features including live migration support.

#### Scenario: Deploy Kube-OVN
- **WHEN** Kube-OVN chart is deployed
- **THEN** Kube-OVN controller and daemon pods are running
- **AND** overlay network is functional

#### Scenario: Persistent pod IPs
- **WHEN** a VM is migrated to another node
- **THEN** the VM's IP address remains unchanged
- **AND** network connectivity is maintained

### Requirement: ClusterAPI Cluster Management
The platform SHALL provide ClusterAPI with KubeVirt infrastructure provider for declarative cluster lifecycle management.

#### Scenario: Deploy ClusterAPI
- **WHEN** ClusterAPI chart is deployed
- **THEN** ClusterAPI controllers are running
- **AND** Cluster, Machine, and KubevirtCluster CRDs are registered

#### Scenario: Provision workload cluster
- **WHEN** a Cluster resource is created with KubevirtCluster infrastructure
- **THEN** control plane VMs are provisioned
- **AND** worker VMs are provisioned
- **AND** cluster API server is reachable via LoadBalancer

### Requirement: VM Live Migration
The platform SHALL support zero-downtime live migration of VirtualMachines between cluster nodes.

#### Scenario: Migrate control plane VM
- **WHEN** a control plane VM is migrated using `virtctl migrate`
- **THEN** the VM moves to target node without shutdown
- **AND** the cluster API server remains available
- **AND** no API requests are dropped

#### Scenario: Migrate worker VM
- **WHEN** a worker VM is migrated
- **THEN** pods running on the worker remain available
- **AND** workload connectivity is maintained

### Requirement: Crossplane Cluster Provisioning
The platform SHALL provide Crossplane compositions for self-service cluster provisioning.

#### Scenario: Define cluster XRD
- **WHEN** KubernetesCluster XRD is applied
- **THEN** KubernetesCluster CRD is registered
- **AND** users can create cluster claims

#### Scenario: Provision cluster via claim
- **WHEN** a KubernetesCluster claim is created
- **THEN** Crossplane creates ClusterAPI resources
- **AND** workload cluster is provisioned successfully
- **AND** kubeconfig is stored in Vault
