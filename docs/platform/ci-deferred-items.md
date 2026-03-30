# CI/CD Deferred Items

Items deprioritized to get basic CI working first. Pick up after CI is operational.

## Open PRs
- **pn-infra #79** — Token refresher CronJob + unified event gateway (generic webhook, security/audit/notification Sensors). Don't merge yet — the EventSource type change will break the current working EventSource. Merge AFTER basic CI is validated.

## Event Gateway (Debate Verdict: Unified Argo Events)
- Migrate EventSource from per-repo `github` type to generic `webhook` type
- Deploy security-enforcer Sensor (secret scanning, code scanning, branch protection, etc.)
- Deploy audit-logger Sensor (all events → Loki)
- Deploy slack-notifier Sensor (PR lifecycle, security alerts)
- Create `security-response` WorkflowTemplate
- Create `secret-scan-push` WorkflowTemplate (trufflehog/gitleaks)
- Configure org-level webhook (replaces per-repo)
- Debate artifacts at: `docs/rfcs/debate-*.md`

## GitHub Token Management
- Replace CronJob approach with Vault GitHub secrets engine plugin (vault-plugin-secrets-github)
- Current state: temporary installation token in Vault (expires, needs manual refresh until automated)

## Phase 1 Remaining (from RFC)
- P1.5: GitHub App for Check Runs (ProficientNow Cloud Platform Bot exists, needs `checks:write`)
- P1.6: GitHub Teams (exist but naming doesn't match RFC)
- P1.7: CODEOWNERS file (neither repo has one)
- P1.8: Remove GitHub Actions CI (pr-validate.yml — replaced by Argo)

## Phases 2-5 (from RFC)
- Phase 2: Auto-labeling, branch protection, Danger.js, Linear integration, push rulesets, GH Enterprise security
- Phase 3: Slack channels, ArgoCD notifications, Prometheus/Alertmanager routing, auto-standup
- Phase 4: Backstage service catalog, TechDocs, CI/CD plugins, Scaffolder templates
- Phase 5: Slack bot, weekly reports, Grafana OnCall, governance fixes

## Slack Webhook
- Placeholder in Vault at `ci/slack` — needs real webhook URL from Slack workspace
