# Zero-human-intervention GitOps platform deployment orchestration

ArgoCD's native sync waves cannot model the complex inter-application dependencies across your 9 stacks with ~50-60 applications. **The recommended architecture combines Ansible for deterministic bootstrap, Argo Workflows as a meta-orchestrator for DAG-based deployment, and Kargo for ongoing environment promotion**—completely eliminating bash scripts and stuck PreSync hooks. This pattern has been validated at scale: CNOE benchmarking demonstrates ArgoCD managing 50,000+ applications across 500 clusters.

## Core architecture for deterministic deployment

Your current pain points—bash script maintenance, stuck PreSync jobs, non-deterministic behavior—stem from trying to model a **dependency DAG** using ArgoCD's linear sync waves. The solution separates concerns across three layers: imperative bootstrap (Ansible), orchestrated deployment (Argo Workflows), and declarative state management (ArgoCD).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           BOOTSTRAP LAYER (Ansible)                          │
│  One-time imperative setup: ArgoCD, Argo Workflows, Argo Events, ESO        │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ORCHESTRATION LAYER (Argo Workflows)                    │
│  DAG-based dependency resolution for platform bootstrap and teardown         │
│  Triggered by: Argo Events sensors (Git webhooks, manual triggers)          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      DEPLOYMENT LAYER (ArgoCD)                               │
│  Sync waves within Applications, health-based progression                    │
│  Self-healing, drift detection, continuous reconciliation                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PROMOTION LAYER (Kargo)                                 │
│  Stage-to-stage promotion (dev → staging → prod)                            │
│  Verification gates, soak times, automated/manual approval                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Why this architecture works**: ArgoCD lacks native app-to-app dependency support (GitHub issue #7437 has 281+ reactions requesting this). Sync waves only order resources within a single Application, not across Applications. Argo Workflows provides true DAG modeling, executing ArgoCD syncs in topological order while waiting for health status between steps.

## Argo Workflows as meta-orchestrator for ArgoCD

Argo Workflows DAGs model your dependency chain precisely: Ceph operator → Ceph cluster → storage classes → Vault/MetalLB/PostgreSQL operator → ingress/external-secrets → applications. Each node in the DAG represents an ArgoCD Application sync operation with health verification.

**ClusterWorkflowTemplate for reusable sync operations:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ClusterWorkflowTemplate
metadata:
  name: argocd-operations
spec:
  templates:
  - name: sync-and-wait
    inputs:
      parameters:
      - name: app-name
      - name: timeout
        default: "600"
    script:
      image: argoproj/argocd:v2.9.0
      command: [bash]
      source: |
        set -e
        argocd app sync {{inputs.parameters.app-name}} \
          --server argocd-server.argocd.svc.cluster.local \
          --auth-token $ARGOCD_TOKEN --grpc-web --timeout {{inputs.parameters.timeout}}
        
        argocd app wait {{inputs.parameters.app-name}} --health --timeout {{inputs.parameters.timeout}} \
          --server argocd-server.argocd.svc.cluster.local \
          --auth-token $ARGOCD_TOKEN --grpc-web
        
        # Output health status for downstream dependencies
        HEALTH=$(argocd app get {{inputs.parameters.app-name}} -o json | jq -r '.status.health.status')
        echo $HEALTH > /tmp/health.txt
      envFrom:
      - secretRef:
          name: argocd-automation-token
    outputs:
      parameters:
      - name: health-status
        valueFrom:
          path: /tmp/health.txt
    
  - name: validate-crd-ready
    inputs:
      parameters:
      - name: group
      - name: version  
      - name: kind
    script:
      image: bitnami/kubectl:latest
      command: [bash]
      source: |
        until kubectl get crd $(echo "{{inputs.parameters.kind}}.{{inputs.parameters.group}}" | tr '[:upper:]' '[:lower:]')s 2>/dev/null; do
          echo "Waiting for CRD..."
          sleep 5
        done
        echo "CRD ready"
```

**Platform bootstrap DAG workflow** modeling your exact dependency chain:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: platform-bootstrap-
spec:
  entrypoint: deploy-platform
  serviceAccountName: argo-workflows-sa
  templates:
  - name: deploy-platform
    dag:
      tasks:
      # Layer 0: Storage Foundation
      - name: ceph-operator
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: ceph-operator}]
      
      - name: ceph-cluster
        dependencies: [ceph-operator]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters:
          - {name: app-name, value: ceph-cluster}
          - {name: timeout, value: "900"}  # Ceph takes longer
      
      - name: storage-classes
        dependencies: [ceph-cluster]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: storage-classes}]
      
      # Layer 1: Platform Services (parallel after storage)
      - name: vault
        dependencies: [storage-classes]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: vault}]
      
      - name: metallb
        dependencies: [storage-classes]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: metallb}]
      
      - name: postgres-operator
        dependencies: [storage-classes]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: postgres-operator}]
      
      # Layer 2: Infrastructure Services
      - name: external-secrets
        dependencies: [vault]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: external-secrets}]
      
      - name: ingress-nginx
        dependencies: [metallb]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: ingress-nginx}]
      
      # Layer 3: Application Dependencies
      - name: temporal-db
        dependencies: [postgres-operator, external-secrets]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: temporal-postgres}]
      
      - name: temporal
        dependencies: [temporal-db, ingress-nginx]
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: temporal}]
      
      # Layer 4: Application Stacks (your 9 stacks as sub-DAGs)
      - name: stack-applications
        dependencies: [temporal, external-secrets, ingress-nginx]
        template: deploy-application-stacks

  - name: deploy-application-stacks
    dag:
      tasks:
      # Each of your 9 stacks as a parallel deployment with internal waves
      - name: stack-1
        templateRef:
          name: argocd-operations
          template: sync-and-wait
          clusterScope: true
        arguments:
          parameters: [{name: app-name, value: stack-1-root}]
      # ... repeat for stacks 2-9
```

This DAG ensures **Temporal won't deploy until postgres-operator, external-secrets, AND ingress are all healthy**—something sync waves alone cannot express.

## Solving the PreSync hook problem permanently

Your PreSync hooks got stuck due to three documented issues: **ttlSecondsAfterFinished race conditions** (job deleted before ArgoCD marks hook complete), **BeforeHookCreation deletion policy races**, and **jobs modifying their own state**. The solution is architectural: move dependency validation from hooks to Argo Workflows.

**Replace this problematic pattern:**
```yaml
# AVOID: PreSync hook for dependency checking
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation  # Race condition!
spec:
  ttlSecondsAfterFinished: 0  # Gets deleted before ArgoCD sees completion!
```

**With this workflow-based validation:**
```yaml
# In your Argo Workflow DAG - dependency is expressed structurally
- name: deploy-app-needing-postgres
  dependencies: [postgres-healthy]  # Workflow won't proceed until postgres passes
  templateRef:
    name: argocd-operations
    template: sync-and-wait
    clusterScope: true
```

**For cases where hooks are still needed** (database migrations, one-time setup), use this safe pattern:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: db-migrate-
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded  # Safer than BeforeHookCreation
spec:
  activeDeadlineSeconds: 300  # Prevents indefinite hang
  backoffLimit: 2
  ttlSecondsAfterFinished: 600  # High value - give ArgoCD time
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: migrate-tool:v1
        command: ["/bin/sh", "-c", "migrate up && exit 0"]
```

## Ansible playbook structure for bootstrap

Replace bash scripts with idempotent Ansible using `kubernetes.core` collection. Ansible handles **Day 0-1 operations** (initial cluster setup, ArgoCD installation), then hands control to ArgoCD for Day 2+ management.

**Directory structure:**
```
platform-bootstrap/
├── ansible.cfg
├── requirements.yml              # kubernetes.core, community.hashi_vault
├── site.yml                      # Master playbook
├── inventories/
│   ├── dev/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       ├── all.yml           # Environment config
│   │       └── vault.yml         # Encrypted secrets
│   ├── staging/
│   └── production/
├── playbooks/
│   ├── bootstrap.yml             # Full platform bootstrap
│   ├── teardown.yml              # Graceful teardown
│   └── validate.yml              # Health verification
└── roles/
    ├── prerequisites/            # CRDs, namespaces, RBAC
    ├── argocd/                   # ArgoCD Helm installation
    ├── argo-workflows/           # Workflow controller
    ├── argo-events/              # Event sources, sensors
    ├── external-secrets/         # ESO + ClusterSecretStore
    └── gitops-handoff/           # Root Application creation
```

**Master bootstrap playbook (`site.yml`):**
```yaml
---
- name: Platform Bootstrap
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars_files:
    - "inventories/{{ env }}/group_vars/all.yml"
    - "inventories/{{ env }}/group_vars/vault.yml"
  
  pre_tasks:
    - name: Validate environment
      ansible.builtin.assert:
        that:
          - env is defined
          - env in ['dev', 'staging', 'production']
        fail_msg: "Specify environment: -e env=dev|staging|production"

  roles:
    - role: prerequisites
      tags: [prereqs]
    
    - role: external-secrets
      tags: [secrets]
    
    - role: argocd
      tags: [argocd]
    
    - role: argo-workflows
      tags: [workflows]
    
    - role: argo-events
      tags: [events]
    
    - role: gitops-handoff
      tags: [handoff]

  post_tasks:
    - name: Trigger platform bootstrap workflow
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: argoproj.io/v1alpha1
          kind: Workflow
          metadata:
            generateName: platform-bootstrap-
            namespace: argo-workflows
          spec:
            workflowTemplateRef:
              name: platform-bootstrap
      register: bootstrap_workflow
    
    - name: Wait for bootstrap completion
      kubernetes.core.k8s_info:
        api_version: argoproj.io/v1alpha1
        kind: Workflow
        namespace: argo-workflows
        label_selectors:
          - "workflows.argoproj.io/workflow-template=platform-bootstrap"
      register: workflow_status
      until:
        - workflow_status.resources | length > 0
        - workflow_status.resources[0].status.phase == "Succeeded"
      retries: 120
      delay: 30
      failed_when: workflow_status.resources[0].status.phase == "Failed"
```

**ArgoCD installation role (`roles/argocd/tasks/main.yml`):**
```yaml
---
- name: Add ArgoCD Helm repository
  kubernetes.core.helm_repository:
    name: argo
    repo_url: https://argoproj.github.io/argo-helm

- name: Create argocd namespace
  kubernetes.core.k8s:
    state: present
    definition:
      apiVersion: v1
      kind: Namespace
      metadata:
        name: argocd
        labels:
          app.kubernetes.io/managed-by: ansible

- name: Install ArgoCD with HA configuration
  kubernetes.core.helm:
    name: argocd
    chart_ref: argo/argo-cd
    release_namespace: argocd
    values:
      controller:
        replicas: 2
        args:
          statusProcessors: "50"
          operationProcessors: "25"
        env:
          - name: ARGOCD_K8S_CLIENT_QPS
            value: "150"
          - name: ARGOCD_K8S_CLIENT_BURST
            value: "300"
      configs:
        cm:
          # Critical: Enable Application health for sync wave dependencies
          resource.customizations.health.argoproj.io_Application: |
            hs = {}
            hs.status = "Progressing"
            hs.message = ""
            if obj.status ~= nil then
              if obj.status.health ~= nil then
                hs.status = obj.status.health.status
                if obj.status.health.message ~= nil then
                  hs.message = obj.status.health.message
                end
              end
            end
            return hs
          # Custom health for Ceph
          resource.customizations.health.ceph.rook.io_CephCluster: |
            hs = {}
            if obj.status ~= nil and obj.status.phase == "Ready" then
              hs.status = "Healthy"
            else
              hs.status = "Progressing"
            end
            return hs
    wait: true
    wait_timeout: 600

- name: Wait for ArgoCD server readiness
  kubernetes.core.k8s_info:
    api_version: apps/v1
    kind: Deployment
    name: argocd-server
    namespace: argocd
  register: argocd_server
  until:
    - argocd_server.resources | length > 0
    - argocd_server.resources[0].status.readyReplicas | default(0) >= 1
  retries: 30
  delay: 10

- name: Create automation token for Argo Workflows
  kubernetes.core.k8s:
    state: present
    definition:
      apiVersion: v1
      kind: Secret
      metadata:
        name: argocd-automation-token
        namespace: argo-workflows
      stringData:
        token: "{{ argocd_automation_token }}"
```

## Argo Events for event-driven orchestration

Argo Events connects Git webhooks to Argo Workflows, enabling **zero-touch deployment** triggered by Git pushes.

**EventBus configuration (Jetstream for production reliability):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: EventBus
metadata:
  name: default
  namespace: argo-events
spec:
  jetstream:
    version: "2.10.10"
    replicas: 3
    persistence:
      storageClassName: ceph-block
      accessMode: ReadWriteOnce
      volumeSize: 10Gi
    streamConfig: |
      maxAge: 72h
```

**Git webhook EventSource:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: platform-gitops
  namespace: argo-events
spec:
  github:
    platform-repo:
      repositories:
        - owner: your-org
          names: [platform-gitops]
      webhook:
        endpoint: /github/push
        port: "12000"
        method: POST
      events: [push]
      apiToken:
        name: github-token
        key: token
      webhookSecret:
        name: github-token
        key: webhook-secret
```

**Sensor triggering bootstrap workflow:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: platform-deploy
  namespace: argo-events
spec:
  dependencies:
  - name: github-push-main
    eventSourceName: platform-gitops
    eventName: platform-repo
    filters:
      data:
      - path: body.ref
        type: string
        value: ["refs/heads/main"]
  triggers:
  - template:
      name: trigger-bootstrap
      argoWorkflow:
        operation: submit
        source:
          resource:
            apiVersion: argoproj.io/v1alpha1
            kind: Workflow
            metadata:
              generateName: gitops-deploy-
            spec:
              workflowTemplateRef:
                name: platform-bootstrap
              arguments:
                parameters:
                - name: git-revision
                  value: ""
        parameters:
        - src:
            dependencyName: github-push-main
            dataKey: body.after
          dest: spec.arguments.parameters.0.value
```

## Kargo for environment promotion

Kargo (GA v1.0+, now v1.5) handles **stage-to-stage promotion** (dev → staging → prod), not intra-environment dependencies. Use it for ongoing deployments after the platform is bootstrapped.

**Project and warehouse configuration:**
```yaml
apiVersion: kargo.akuity.io/v1alpha1
kind: Project
metadata:
  name: platform
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Warehouse
metadata:
  name: platform-artifacts
  namespace: platform
spec:
  subscriptions:
  - git:
      repoURL: https://github.com/your-org/platform-gitops
      includePaths: ["applications/**"]
      commitSelectionStrategy: NewestFromBranch
      branch: main
```

**Stage pipeline with verification and soak time:**
```yaml
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: staging
  namespace: platform
spec:
  requestedFreight:
  - origin:
      kind: Warehouse
      name: platform-artifacts
    sources:
      stages: [dev]
  promotionTemplate:
    spec:
      steps:
      - uses: git-clone
        config:
          repoURL: https://github.com/your-org/platform-gitops
          checkout:
          - branch: main
            path: ./repo
      - uses: kustomize-set-image
        config:
          path: ./repo/applications/staging
          images:
          - image: ghcr.io/your-org/app
      - uses: git-commit
        config:
          path: ./repo
          messageFromSteps:
          - promote-to-staging
      - uses: argocd-update
        config:
          apps:
          - name: staging-apps
            sources:
            - repoURL: https://github.com/your-org/platform-gitops
  verification:
    analysisTemplates:
    - name: smoke-tests
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: prod
  namespace: platform
spec:
  requestedFreight:
  - origin:
      kind: Warehouse
      name: platform-artifacts
    sources:
      stages: [staging]
      requiredSoakTime: 24h      # Must be stable in staging for 24h
      availabilityStrategy: All  # All upstream stages must verify
```

## Consolidating sync wave strategy

Your current -30 to +50 range is too spread. Consolidate to **7 meaningful waves** aligned with your dependency layers:

```yaml
# Wave assignment for ~60 applications across 9 stacks

# Wave -3: CRDs and Operators (must exist before instances)
- ceph-operator, postgres-operator, vault-operator, cert-manager

# Wave -2: Storage Foundation
- ceph-cluster, storage-classes

# Wave -1: Core Platform Services (parallel)
- vault, metallb, external-secrets-operator

# Wave 0: Platform Infrastructure
- ingress-nginx, external-secrets (ClusterSecretStore)
- cert-manager (ClusterIssuer)

# Wave 1: Databases and Stateful Services
- postgresql-instances, redis, temporal-db

# Wave 2: Application Infrastructure
- temporal, message-queues, service-mesh

# Wave 3+: Application Stacks (your 9 stacks)
- Each stack as an App-of-Apps with internal waves 0-3
```

**Critical ArgoCD configuration for Application health propagation** (required for App-of-Apps sync wave dependencies):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  resource.customizations.health.argoproj.io_Application: |
    hs = {}
    hs.status = "Progressing"
    hs.message = ""
    if obj.status ~= nil then
      if obj.status.health ~= nil then
        hs.status = obj.status.health.status
        if obj.status.health.message ~= nil then
          hs.message = obj.status.health.message
        end
      end
    end
    return hs
```

Without this configuration, ArgoCD removed Application health assessment in v1.8, causing sync waves on nested Applications to not wait for child health.

## Validation and health assurance

**Ansible validation playbook (`playbooks/validate.yml`):**
```yaml
---
- name: Platform Health Validation
  hosts: localhost
  connection: local
  
  tasks:
  - name: Get all ArgoCD Applications
    kubernetes.core.k8s_info:
      api_version: argoproj.io/v1alpha1
      kind: Application
      namespace: argocd
    register: all_apps
  
  - name: Validate all applications healthy and synced
    ansible.builtin.assert:
      that:
        - item.status.health.status == "Healthy"
        - item.status.sync.status == "Synced"
      fail_msg: "{{ item.metadata.name }}: health={{ item.status.health.status }}, sync={{ item.status.sync.status }}"
      success_msg: "{{ item.metadata.name }}: ✓ healthy"
    loop: "{{ all_apps.resources }}"
    loop_control:
      label: "{{ item.metadata.name }}"
  
  - name: Validate storage classes available
    kubernetes.core.k8s_info:
      api_version: storage.k8s.io/v1
      kind: StorageClass
    register: storage_classes
    failed_when: storage_classes.resources | length == 0
  
  - name: Validate LoadBalancer IPs assigned
    kubernetes.core.k8s_info:
      api_version: v1
      kind: Service
      field_selectors:
        - spec.type=LoadBalancer
    register: lb_services
  
  - name: Check all LBs have external IP
    ansible.builtin.assert:
      that:
        - item.status.loadBalancer.ingress | length > 0
      fail_msg: "Service {{ item.metadata.name }} has no external IP"
    loop: "{{ lb_services.resources }}"
    loop_control:
      label: "{{ item.metadata.name }}"
  
  - name: HTTP health checks for critical endpoints
    ansible.builtin.uri:
      url: "{{ item }}"
      status_code: [200, 204]
      timeout: 30
    loop:
      - "https://argocd.{{ domain }}/healthz"
      - "https://vault.{{ domain }}/v1/sys/health"
      - "https://temporal.{{ domain }}/health"
    retries: 3
    delay: 10
```

## Migration strategy from bash scripts

**Phase 1 (Week 1-2): Ansible foundation**
- Convert existing bash bootstrap to Ansible playbooks
- Implement role structure for each component
- Test bootstrap/teardown idempotency
- Keep existing ArgoCD Apps unchanged

**Phase 2 (Week 3-4): Argo Workflows orchestration**
- Deploy Argo Workflows controller via Ansible
- Create ClusterWorkflowTemplates for ArgoCD operations
- Build DAG workflow matching current dependency chain
- Test workflow-based bootstrap in dev environment

**Phase 3 (Week 5-6): Argo Events integration**
- Deploy Argo Events with Jetstream EventBus
- Configure Git webhook EventSource
- Create Sensor for GitOps triggers
- Validate end-to-end: git push → workflow → deployment

**Phase 4 (Week 7-8): Kargo promotion**
- Deploy Kargo controller
- Define Warehouses and Stages for dev → staging → prod
- Configure verification templates
- Enable auto-promotion for non-production stages

**Phase 5 (Week 9-10): Validation and cleanup**
- Implement comprehensive validation playbooks
- Remove all bash scripts from repository
- Document operational runbooks
- Establish monitoring and alerting

## Rollback and recovery strategies

**Workflow-level rollback:**
```yaml
- name: deploy-with-rollback
  dag:
    tasks:
    - name: deploy-app
      template: sync-and-wait
      arguments:
        parameters: [{name: app-name, value: my-app}]
    
    - name: rollback-on-failure
      dependencies: [deploy-app]
      when: "{{tasks.deploy-app.status}} == Failed"
      template: rollback
      arguments:
        parameters: [{name: app-name, value: my-app}]
```

**Kargo rollback via previous Freight:**
- Kargo maintains Freight history
- Rollback = promote previous Freight to Stage
- Available via UI or CLI: `kargo promote --stage prod --freight <previous-freight-id>`

**Emergency recovery playbook:**
```yaml
# playbooks/emergency-recovery.yml
- name: Emergency Platform Recovery
  hosts: localhost
  tasks:
  - name: Force sync all Applications
    kubernetes.core.k8s_exec:
      namespace: argocd
      pod: "{{ argocd_server_pod }}"
      command: argocd app sync --all --force
  
  - name: Restart stuck operators
    kubernetes.core.k8s:
      state: absent
      api_version: v1
      kind: Pod
      namespace: "{{ item.namespace }}"
      label_selectors:
        - "{{ item.selector }}"
    loop:
      - {namespace: argocd, selector: "app.kubernetes.io/name=argocd-application-controller"}
      - {namespace: argo-workflows, selector: "app=workflow-controller"}
```

## Conclusion

This architecture delivers **guaranteed deterministic deployments** through structural dependency modeling in Argo Workflows DAGs, replacing brittle sync waves and stuck PreSync hooks. The combination of Ansible for bootstrap, Argo Workflows for orchestration, ArgoCD for state management, and Kargo for promotion provides complete lifecycle coverage.

Key success factors:
- **Enable Application health propagation** in ArgoCD ConfigMap—without this, App-of-Apps sync waves fail silently
- **Use workflow DAGs for cross-application dependencies**, reserving sync waves for intra-application ordering
- **Implement custom health checks** for all CRDs (Ceph, PostgreSQL clusters, Vault) to prevent premature progression
- **Design for forward-only in production**—catch issues in staging with verification and soak times rather than relying on rollback

The CNOE benchmarks validate this pattern at 50,000+ applications across 500 clusters. Your 60-application platform will benefit from the same architectural principles that power the largest GitOps deployments in production.