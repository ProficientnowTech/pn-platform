# P2 acceptance — real target cluster (Talos up via P3 + ephemeral Vault reachable). Not CI.

`./deploy.sh <CLUSTER>` end-to-end. Expected: kapp exits `0/3`; all 4 change-groups converged;
`kubectl get clustersecretstore vault-backend` = `Ready=True`; `argocd-server` Deployment Available.
Asserts on-cluster: Cilium L2 VIP answers ARP; a PVC binds on `proxmox-zfs-r1`; an ExternalSecret
materialises from the ephemeral Vault; ArgoCD reachable. **Gated on the on-prem-primary milestone.**
