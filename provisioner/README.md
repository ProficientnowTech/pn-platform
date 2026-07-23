# Provisioner Module

Contains the templating pipeline (Ansible, scripts, docs) that converts role definitions + environment data into bootable images. Builds are driven through the `api` CLI and publish metadata under `api/outputs/<env>/provisioner/` for infrastructure providers.

```bash
# 1. Materialize the config package for an environment
./api/bin/api generate env --id development --config core --skip-validate

# 2. Build an image for a specific role (static + dynamic config resolved from API outputs)
./api/bin/api provision build --role k8s-master --env development

# → metadata stored in api/outputs/development/provisioner/k8s-master.json
# → image output stored under provisioner/outputs/development/k8s-master.img
```

See `provisioner/scripts/smoke-test.sh` for a quick validation routine that exercises the flow end to end.

---

## Requirements

### Input Files
- **From Config**: Role definitions (base configuration per role)
- **From API**: `api/outputs/<env>/provisioner.json` - Merged config (static + dynamic)
- **Module Environment**: `provisioner/environments/<env>.yaml` - Ansible vault passwords, SSH keys, role overrides

### Required Tools
- Ansible 2.x+
- Python 3.x
- SSH access to target hosts

### Folder Structure
```
provisioner/
├── ansible.cfg
├── requirements.yml
├── inventories/<env>/hosts.yml
├── playbooks/site.yml
└── roles/
    ├── base/
    ├── software/
    ├── system_settings/
    ├── disk_management/
    ├── identity_users/
    ├── directories/
    ├── networking/
    └── security/
```

---

## Outputs

### Provisioned Images
- **Location**: `provisioner/outputs/<env>/<role>.img`
- **Metadata**: `api/outputs/<env>/provisioner/<role>.json`
  - Role name, environment, artifact path, checksum
  - Remote storage placeholders (bucket, path)
  - Build timestamp

### Configured Hosts
- VMs/instances with applied role configuration
- Base system (timezone, locale, logging)
- Software packages installed
- System settings applied
- Users/directories created
- Network configuration
- Security hardening (if enabled)

---

## Integration
- **Depends On**: Infrastructure (VMs must exist), API (generates config)
- **Consumed By**: Container Orchestration (expects configured hosts)

---

## Deploying PNow ATS Services

Use the dedicated playbook to deploy Docker Compose services from your private GitHub repo to `app_server` hosts. The playbook checks WireGuard health first and only runs the `wireguard` role if the WG interface/service is missing or inactive.

```bash
cd provisioner
ansible-playbook -i inventory/production/hosts.yml playbooks/app_services_deploy.yml
```

To stop all deployed services:

```bash
cd provisioner
ansible-playbook -i inventory/production/hosts.yml playbooks/app_services_teardown.yml
```

### Short Service Flags

Use the wrapper script for short selectors instead of long `-e` JSON:

```bash
cd provisioner
./scripts/deploy-app-services.sh --host app-server-01 --pi-scrape
./scripts/deploy-app-services.sh --host app-server-01 --pi-scrape kafka-broker-1 redis
./scripts/deploy-app-services.sh --host app-server-01 --teardown --pi-scrape
```

Pass extra Ansible args after `--`:

```bash
./scripts/deploy-app-services.sh --host app-server-01 --pi-scrape -- --check
```

Deployment variables live in `inventory/production/group_vars/app_server.yml`:
- `app_deploy_source_mode` (`git` or `local_sync`)
- `app_deploy_repo_url`
- `app_deploy_repo_version`
- `app_deploy_repo_key_path`
- `app_deploy_repo_ssh_key` (recommended via Ansible Vault)
- `app_deploy_dest_path`
- `app_deploy_compose_files` (one or more compose stacks)
  - Example: `docker/docker-compose.yml`, `apps/backend/tasks-reminders/docker-compose.yml`
- `app_deploy_target_compose_files` (optional runtime filter for partial deploys)
- `app_deploy_env_src_local_path`
- `app_deploy_env_content` (recommended via Ansible Vault)
- `app_deploy_env_dest_relpath`
- `app_deploy_env_files` (additional local `.env` sync list with `src`, `dest`, optional `required: false`)
- `app_deploy_src_local_path` (controller-side app repo path; relative env `src` values are resolved from here)
- `app_deploy_env_overrides` (force specific env keys after sync, e.g. missing required vars)
- `app_deploy_require_wireguard`
- `app_deploy_manage_wireguard` (auto-remediate WG only when needed)
- `app_deploy_services` (optional subset)
- `app_deploy_services_by_compose` (optional per-compose subset)
- `app_deploy_selectors` (short selector list for playbook-only targeting)
- `app_deploy_external_network_env_compose_files` (which compose files should trigger auto-create of env-driven external networks)
- `app_deploy_create_prereq_dirs` (auto-create host bind mount directories before compose up)
- `app_deploy_prereq_dirs` (extra directories to create explicitly)
- `app_deploy_prereq_dir_attrs` (optional per-directory owner/group/mode overrides, useful for services like Kafka running as uid 1000)

### Playbook-Only Short Targeting

Use selectors without long JSON:

```bash
cd provisioner
ansible-playbook -i inventory/production/hosts.yml playbooks/app_services_deploy.yml --limit app-server-01 -e app_deploy_selectors=pi-scrape
ansible-playbook -i inventory/production/hosts.yml playbooks/app_services_deploy.yml --limit app-server-01 -e app_deploy_selectors=kafka-broker-1,redis
ansible-playbook -i inventory/production/hosts.yml playbooks/app_services_deploy.yml --limit app-server-01 -e app_deploy_selectors=pi-scrape,audit-api-service
```

`app_deploy_selector_map` now includes all services discovered from the repository compose files plus convenience aliases (for example `pi-scrape`, `audit-service`, `tasks-reminders`).
