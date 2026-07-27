# infrastructure/ — Terraform (bpg) + Talos provisioning

> **Old flow removed (P0, 2026-07-28).** The api-CLI-driven Packer/Terraform provisioning
> (`deploy.sh`, `platforms/{baremetal,cloud,proxmox}`, `environments/`) depended on the deleted
> api-CLI monorepo (`deploy.sh` shelled into `$API_BIN generate env`) — all removed.
>
> The new provisioning is **bpg/proxmox + Talos**: the kapp foundation lands at
> `infrastructure/bootstrap/` (P2) and the Talos-VM + vehicle terraform under
> `provisioner/bootstrapper/` (P3). See `docs/design/cluster-bootstrap-orchestration.md` and
> `docs/plans/2026-07-28-P{2,3}-*.md`. Reference configs: ovh-infra `onprem/platform-live`.
