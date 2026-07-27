<!--
id:             DESIGN-PNPLATFORM-FACTORY-VALUES-SCHEMA-2026-07-27
status:         design; feeds the P1 app-factory chart plan (_validate + values.schema.json)
target_repo:    THIS repo (ProficientNowTech/pn-platform, branch main)
related:        docs/design/app-factory-label-taxonomy.md
-->

# Design — `app-factory` values & validation schema

Concrete values for the 9-label taxonomy so the factory validates **every app at render time**
(`fail` on missing/invalid) and CI can validate the same shape with a JSON Schema.

## 1. What is AUTHORED vs from CONTEXT vs DERIVED

- **Authored per app** (the app entry): `name, domain, version, team, tier, dependency-layer` (required) +
  `dr-role, lifecycle, contact, dependencies, source, syncPolicy` (optional).
- **From context** (passed by the stamper, per cluster×env): `cluster, environment, destination`. These
  are placement facts — not repeated in every app entry.
- **Derived** (factory computes, never authored): `app.kubernetes.io/instance` (`<name>-<cluster>`),
  `argocd.argoproj.io/sync-wave` + `kapp.k14s.io/change-group|change-rule` (from `dependency-layer`).

## 2. The enum definitions (the closed sets)

| Field | Allowed values |
|---|---|
| `domain` (→ `app.kubernetes.io/part-of`) | `infrastructure` `storage` `databases` `security` `monitoring` `developer-platform` `data-streaming` `ml-infra` `application` `backup-dr` |
| `environment` | `dev` `staging` `prod` `preview` |
| `tier` | `critical` `high` `standard` `low` |
| `dr-role` | `none` `source` `replica` (default `none`) |
| `lifecycle` | `active` `experimental` `deprecated` (default `active`) |
| `dependency-layer` | `foundation` `core` `platform` `application` |
| `cluster` | `onprem-primary` `contabo-standby` `azure-dr` `ovh-proving-ground` (the registry keys) |
| `team` | **configurable** — default `platform` `data` `sre` `ml` `app` (from `.Values.factory.teams`) |

### Patterns (non-enum strings)
| Field | Pattern | Note |
|---|---|---|
| `name` | `^[a-z][a-z0-9-]{0,40}$` | dns-ish slug |
| `version` | `^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$` | valid k8s **label value** (≤63); semver or short hash, never a full commit SHA (cardinality) |
| every label value | same ≤63 k8s label-value rule | enums satisfy this by construction |

### Derived: `dependency-layer` → wave
`foundation → -25 · core → -5 · platform → 10 · application → 30` (both `sync-wave` and the kapp
`change-group platform.pnats.cloud/layer-<name>` + `change-rule "upsert after upserting …/layer-<prev>"`).

## 3. The app-entry JSON Schema (`app-factory/schemas/app-entry.schema.json`)

Used by CI (`ajv`/`kubeconform`-adjacent) and mirrored by the `_validate` template. Draft-07:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "app-factory app entry",
  "type": "object",
  "additionalProperties": false,
  "required": ["name", "domain", "version", "team", "tier", "dependency-layer", "source"],
  "properties": {
    "name":    { "type": "string", "pattern": "^[a-z][a-z0-9-]{0,40}$" },
    "domain":  { "enum": ["infrastructure","storage","databases","security","monitoring","developer-platform","data-streaming","ml-infra","application","backup-dr"] },
    "version": { "type": "string", "pattern": "^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$" },
    "team":    { "type": "string", "pattern": "^[a-z][a-z0-9-]{0,40}$" },
    "tier":    { "enum": ["critical","high","standard","low"] },
    "dependency-layer": { "enum": ["foundation","core","platform","application"] },
    "dr-role":   { "enum": ["none","source","replica"], "default": "none" },
    "lifecycle": { "enum": ["active","experimental","deprecated"], "default": "active" },
    "contact":   { "type": "string", "minLength": 1 },
    "dependencies": { "type": "array", "items": { "type": "string", "pattern": "^[a-z][a-z0-9-]{0,40}$" } },
    "source":    { "type": "object" },
    "syncPolicy":{ "type": "object" }
  }
}
```

*(`team`'s pattern is a slug; membership in `.Values.factory.teams` is checked by the template, not the
static schema, because the team list is chart-config, not fixed.)*

## 4. The context schema (passed by the stamper)

```json
{ "type": "object", "required": ["cluster","environment","destination"],
  "properties": {
    "cluster":     { "enum": ["onprem-primary","contabo-standby","azure-dr","ovh-proving-ground"] },
    "environment": { "enum": ["dev","staging","prod","preview"] },
    "destination": { "type": "object" } } }
```

## 5. The factory's own config schema (`values.schema.json`)

Helm auto-validates the *chart's* `values.yaml` against `values.schema.json`. The factory's config is small:
```json
{ "$schema":"http://json-schema.org/draft-07/schema#", "type":"object",
  "properties": { "factory": { "type":"object",
    "properties": { "teams": { "type":"array", "items": {"type":"string","pattern":"^[a-z][a-z0-9-]{0,40}$"},
                               "default": ["platform","data","sre","ml","app"] } } } } }
```

## 6. How validation runs (two gates, same rules)

1. **Render-time (primary) — the `_validate` template.** Because the factory is a *library* chart consumed
   per app entry, Helm's `values.schema.json` can't see the per-app dict — so `_validate` is the enforcer:
   for each entry it checks required-present, enum-membership (incl. `team ∈ .Values.factory.teams`),
   pattern match, and `dependency-layer` monotonicity vs `dependencies`, and `fail`s with a precise message.
   (This is P1 Tasks 3 + 7, now re-pointed at *these* fields.)
2. **CI (defense-in-depth) — the JSON Schema (§3/§4).** A pipeline step validates each app entry against
   `app-entry.schema.json` (catches typos before Helm even runs). The static schema and `_validate` assert
   the **same** enums; keep them in sync (P1 adds a test that renders every enum-invalid case → `fail`).

## 7. Fail-message contract (so errors are actionable)

`_validate` fails with, e.g.:
`app-factory: app "harbor" invalid tier "medium" (allowed: critical|high|standard|low)`
Always: the app name, the field, the bad value, and the allowed set.

## Out of scope
- The chart implementation itself — **P1**, which this schema now drives.
- The Kyverno `ClusterPolicy` that re-asserts these enums cluster-side — later.
