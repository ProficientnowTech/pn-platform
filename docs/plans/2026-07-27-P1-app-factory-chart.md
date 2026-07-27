# P1 — `app-factory` Library Chart — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` or `superpowers:executing-plans`. `- [ ]` checkboxes.

**Goal:** Implement the `app-factory` Helm **library chart** that stamps every AppProject + Application with the **9-label taxonomy**, derives `sync-wave` from `dependency-layer`, and **fails the render** on any missing/invalid value — fully unit-tested (`helm-unittest`) + schema-validated (`kubeconform`), no cluster required.

**Architecture:** A `type: library` chart of `define` helpers. Enums live once in `_enums.tpl`; `_validate` enforces required-fields + enums + patterns + team-membership + dependency monotonicity; `_labels` stamps the 9 labels; `_application`/`_appproject` render the CRs. A tiny `tests-consumer/` chart renders the helpers so `helm-unittest` can assert on output. Sources of truth: `docs/design/app-factory-label-taxonomy.md` + `docs/design/app-factory-values-schema.md`.

**Tech Stack:** Helm 3, `helm-unittest`, `kubeconform`.

## Global Constraints
- Repo `pn-platform` `main`; push HTTPS + gh token; identity `Shaik Noorullah <snoorullah@proficientnow.com>`.
- Chart path `platform/app-factory`; consumer/test chart `platform/app-factory/tests-consumer/`.
- **Hyphenated keys** (`dr-role`, `dependency-layer`) MUST be read with `get $map "dr-role"` — dot-access (`.dr-role`) does not work in Helm/sprig.
- **Authored per app:** `name,domain,version,team,tier,dependency-layer` (required) + `dr-role,lifecycle,contact,dependencies,source,syncPolicy` (optional). **From context (dict keys `cluster,environment,destination`).** **Derived:** sync-wave (never authored).
- Enums verbatim from the values-schema doc; `dependency-layer→wave`: `foundation -25 · core -5 · platform 10 · application 30`.
- `metadata.name` = `app.name` (each cluster runs its own ArgoCD; the `cluster` label records placement).

---

### Task 1: Harness — consumer chart + helm-unittest

**Files:** Create `platform/app-factory/tests-consumer/{Chart.yaml,templates/render.yaml,tests/harness_test.yaml}`

**Interfaces:** Produces the harness later tasks render against.

- [ ] **Step 1:** `Chart.yaml`
```yaml
apiVersion: v2
name: tests-consumer
version: 0.0.0
dependencies: [{name: app-factory, version: 0.0.0, repository: "file://.."}]
```
- [ ] **Step 2:** empty `templates/render.yaml` (`{{- /* filled by later tasks */ -}}`)
- [ ] **Step 3:** `tests/harness_test.yaml`
```yaml
suite: harness
templates: [render.yaml]
tests: [{it: renders nothing, asserts: [{hasDocuments: {count: 0}}]}]
```
- [ ] **Step 4:** `cd platform/app-factory/tests-consumer && helm dependency build && helm unittest .` → `1 passed`
- [ ] **Step 5:** Commit — `test(app-factory): consumer chart + helm-unittest harness`

### Task 2: `_enums.tpl` — the closed sets (shared)

**Files:** Create `platform/app-factory/templates/_enums.tpl`

**Interfaces:** Produces `app-factory.enums` — takes `.` (any ctx), returns a **JSON** dict of `field → allowed list`. Callers do `include "app-factory.enums" . | fromJson`.

- [ ] **Step 1: Implement** (no test alone — exercised via Task 4)
```yaml
{{- define "app-factory.enums" -}}
{{ dict
  "domain" (list "infrastructure" "storage" "databases" "security" "monitoring" "developer-platform" "data-streaming" "ml-infra" "application" "backup-dr")
  "environment" (list "dev" "staging" "prod" "preview")
  "tier" (list "critical" "high" "standard" "low")
  "dr-role" (list "none" "source" "replica")
  "lifecycle" (list "active" "experimental" "deprecated")
  "dependency-layer" (list "foundation" "core" "platform" "application")
  "cluster" (list "onprem-primary" "contabo-standby" "azure-dr" "ovh-proving-ground")
  | toJson }}
{{- end -}}
```
- [ ] **Step 2:** `helm dependency build` in tests-consumer succeeds (chart still parses).
- [ ] **Step 3:** Commit — `feat(app-factory): _enums closed sets`

### Task 3: `_syncwave.tpl` — layer → wave

**Files:** Create `platform/app-factory/templates/_syncwave.tpl`; Test `tests-consumer/tests/syncwave_test.yaml`

**Interfaces:** `app-factory.syncwave` — input `(dict "layer" <string>)` → wave string; `fail`s on unknown.

- [ ] **Step 1: Failing test** — append to `render.yaml`:
```yaml
{{- if .Values.tsLayer }}
apiVersion: v1
kind: ConfigMap
metadata: {name: sw}
data: {wave: {{ include "app-factory.syncwave" (dict "layer" .Values.tsLayer) | quote }}}
{{- end }}
```
```yaml
# syncwave_test.yaml
suite: syncwave
templates: [render.yaml]
tests:
  - {it: foundation, set: {tsLayer: foundation}, asserts: [{equal: {path: data.wave, value: "-25"}}]}
  - {it: application, set: {tsLayer: application}, asserts: [{equal: {path: data.wave, value: "30"}}]}
  - {it: unknown fails, set: {tsLayer: bogus}, asserts: [{failedTemplate: {errorMessage: "app-factory: unknown dependency-layer \"bogus\""}}]}
```
- [ ] **Step 2:** `helm unittest .` → FAIL (undefined)
- [ ] **Step 3: Implement**
```yaml
{{- define "app-factory.syncwave" -}}
{{- $m := dict "foundation" "-25" "core" "-5" "platform" "10" "application" "30" -}}
{{- if not (hasKey $m .layer) -}}{{- fail (printf "app-factory: unknown dependency-layer %q" .layer) -}}{{- end -}}
{{- get $m .layer -}}
{{- end -}}
```
- [ ] **Step 4:** `helm dependency build && helm unittest .` → PASS (3)
- [ ] **Step 5:** Commit — `test+feat(app-factory): _syncwave`

### Task 4: `_validate.tpl` — required + enums + patterns + team + monotonicity

**Files:** Create `platform/app-factory/templates/_validate.tpl`; Test `tests-consumer/tests/validate_test.yaml`

**Interfaces:** `app-factory.validate` — input `(dict "app" <entry> "cluster" <str?> "environment" <str?> "teams" <list?> "index" <map?>)`; emits nothing on success; `fail`s with `app+field+bad-value+allowed`. Required entry fields: `name,domain,version,team,tier,dependency-layer`.

- [ ] **Step 1: Failing tests** — append to `render.yaml`:
```yaml
{{- if .Values.vApp }}{{ include "app-factory.validate" (dict "app" .Values.vApp "cluster" .Values.vCluster "environment" .Values.vEnv "teams" (list "platform" "data") "index" .Values.vIndex) }}{{- end }}
```
```yaml
# validate_test.yaml
suite: validate
templates: [render.yaml]
tests:
  - it: missing tier fails
    set: {vApp: {name: x, domain: security, version: "1.0.0", team: platform, dependency-layer: core}}
    asserts: [{failedTemplate: {errorMessage: "app-factory: app \"x\" missing required field \"tier\""}}]
  - it: bad domain fails
    set: {vApp: {name: x, domain: nope, version: "1.0.0", team: platform, tier: standard, dependency-layer: core}}
    asserts: [{failedTemplate: {errorMessage: "app-factory: app \"x\" invalid domain \"nope\" (allowed: infrastructure|storage|databases|security|monitoring|developer-platform|data-streaming|ml-infra|application|backup-dr)"}}]
  - it: team not in allowed set fails
    set: {vApp: {name: x, domain: security, version: "1.0.0", team: rogue, tier: standard, dependency-layer: core}}
    asserts: [{failedTemplate: {errorMessage: "app-factory: app \"x\" invalid team \"rogue\" (allowed: platform|data)"}}]
  - it: bad cluster context fails
    set: {vCluster: bogus, vApp: {name: x, domain: security, version: "1.0.0", team: platform, tier: standard, dependency-layer: core}}
    asserts: [{failedTemplate: {errorMessage: "app-factory: invalid cluster \"bogus\""}}]
  - it: dependency on a later layer fails
    set: {vIndex: {b: platform}, vApp: {name: a, domain: security, version: "1.0.0", team: platform, tier: standard, dependency-layer: foundation, dependencies: [b]}}
    asserts: [{failedTemplate: {errorMessage: "app-factory: app \"a\" (layer foundation) depends on \"b\" at a later layer platform"}}]
  - it: valid app passes
    set: {vApp: {name: x, domain: security, version: "1.0.0", team: platform, tier: standard, dependency-layer: core}}
    asserts: [{hasDocuments: {count: 0}}]
```
- [ ] **Step 2:** `helm unittest .` → FAIL
- [ ] **Step 3: Implement**
```yaml
{{- define "app-factory.validate" -}}
{{- $a := .app -}}{{- $n := $a.name | default "?" -}}
{{- $e := include "app-factory.enums" . | fromJson -}}
{{- $teams := .teams | default (list "platform" "data" "sre" "ml" "app") -}}
{{- range $f := list "name" "domain" "version" "team" "tier" "dependency-layer" -}}
{{- if not (hasKey $a $f) -}}{{- fail (printf "app-factory: app %q missing required field %q" $n $f) -}}{{- end -}}
{{- end -}}
{{- if not (regexMatch "^[a-z][a-z0-9-]{0,40}$" $a.name) -}}{{- fail (printf "app-factory: app %q invalid name %q (slug ^[a-z][a-z0-9-]{0,40}$)" $n $a.name) -}}{{- end -}}
{{- if not (regexMatch "^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$" $a.version) -}}{{- fail (printf "app-factory: app %q invalid version %q (must be a valid label value)" $n $a.version) -}}{{- end -}}
{{- range $k := list "domain" "tier" "dependency-layer" -}}
{{- if not (has (get $a $k) (get $e $k)) -}}{{- fail (printf "app-factory: app %q invalid %s %q (allowed: %s)" $n $k (get $a $k) (join "|" (get $e $k))) -}}{{- end -}}
{{- end -}}
{{- $dr := get $a "dr-role" | default "none" -}}{{- if not (has $dr (get $e "dr-role")) -}}{{- fail (printf "app-factory: app %q invalid dr-role %q" $n $dr) -}}{{- end -}}
{{- $lc := $a.lifecycle | default "active" -}}{{- if not (has $lc (get $e "lifecycle")) -}}{{- fail (printf "app-factory: app %q invalid lifecycle %q" $n $lc) -}}{{- end -}}
{{- if not (has $a.team $teams) -}}{{- fail (printf "app-factory: app %q invalid team %q (allowed: %s)" $n $a.team (join "|" $teams)) -}}{{- end -}}
{{- if .cluster -}}{{- if not (has .cluster (get $e "cluster")) -}}{{- fail (printf "app-factory: invalid cluster %q" .cluster) -}}{{- end -}}{{- end -}}
{{- if .environment -}}{{- if not (has .environment (get $e "environment")) -}}{{- fail (printf "app-factory: invalid environment %q" .environment) -}}{{- end -}}{{- end -}}
{{- if and (hasKey $a "dependencies") (hasKey . "index") -}}
{{- $order := dict "foundation" 0 "core" 1 "platform" 2 "application" 3 -}}
{{- $mine := get $order (get $a "dependency-layer") -}}
{{- range $d := $a.dependencies -}}
{{- if not (hasKey $.index $d) -}}{{- fail (printf "app-factory: app %q depends on unknown %q" $n $d) -}}{{- end -}}
{{- if gt (int (get $order (get $.index $d))) (int $mine) -}}{{- fail (printf "app-factory: app %q (layer %s) depends on %q at a later layer %s" $n (get $a "dependency-layer") $d (get $.index $d)) -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
```
- [ ] **Step 4:** `helm unittest .` → PASS (6)
- [ ] **Step 5:** Commit — `test+feat(app-factory): _validate (fields+enums+patterns+team+deps)`

### Task 5: `_labels.tpl` — the 9-label stamp

**Files:** Create `platform/app-factory/templates/_labels.tpl`; Test `tests-consumer/tests/labels_test.yaml`

**Interfaces:** `app-factory.labels` — input `(dict "app" <entry> "cluster" <str> "environment" <str> "teams" <list?>)`; validates first; emits the 9 labels.

- [ ] **Step 1: Failing test** — append to `render.yaml`:
```yaml
{{- if .Values.lApp }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: lbl
  labels:
    {{- include "app-factory.labels" (dict "app" .Values.lApp "cluster" "onprem-primary" "environment" "prod") | nindent 4 }}
{{- end }}
```
```yaml
# labels_test.yaml
suite: labels
templates: [render.yaml]
tests:
  - it: stamps the 9 labels
    set: {lApp: {name: harbor, domain: developer-platform, version: "2.11.0", team: platform, tier: standard, dependency-layer: platform, dr-role: none}}
    asserts:
      - {equal: {path: "metadata.labels['app.kubernetes.io/part-of']", value: developer-platform}}
      - {equal: {path: "metadata.labels['app.kubernetes.io/version']", value: "2.11.0"}}
      - {equal: {path: "metadata.labels['platform.pnats.cloud/team']", value: platform}}
      - {equal: {path: "metadata.labels['platform.pnats.cloud/environment']", value: prod}}
      - {equal: {path: "metadata.labels['platform.pnats.cloud/cluster']", value: onprem-primary}}
      - {equal: {path: "metadata.labels['platform.pnats.cloud/dependency-layer']", value: platform}}
      - {equal: {path: "metadata.labels['platform.pnats.cloud/lifecycle']", value: active}}
```
- [ ] **Step 2:** `helm unittest .` → FAIL
- [ ] **Step 3: Implement**
```yaml
{{- define "app-factory.labels" -}}
{{- include "app-factory.validate" (dict "app" .app "cluster" .cluster "environment" .environment "teams" .teams) -}}
{{- $a := .app -}}
app.kubernetes.io/part-of: {{ $a.domain | quote }}
app.kubernetes.io/version: {{ $a.version | quote }}
platform.pnats.cloud/team: {{ $a.team | quote }}
platform.pnats.cloud/environment: {{ .environment | quote }}
platform.pnats.cloud/tier: {{ $a.tier | quote }}
platform.pnats.cloud/cluster: {{ .cluster | quote }}
platform.pnats.cloud/dr-role: {{ get $a "dr-role" | default "none" | quote }}
platform.pnats.cloud/lifecycle: {{ $a.lifecycle | default "active" | quote }}
platform.pnats.cloud/dependency-layer: {{ get $a "dependency-layer" | quote }}
{{- end -}}
```
- [ ] **Step 4:** `helm unittest .` → PASS
- [ ] **Step 5:** Commit — `test+feat(app-factory): _labels 9-label stamp`

### Task 6: `_application.tpl`

**Files:** Create `platform/app-factory/templates/_application.tpl`; Test `tests-consumer/tests/application_test.yaml`

**Interfaces:** `app-factory.application` — input `(dict "app" <entry> "cluster" <str> "environment" <str> "destination" <map> "teams" <list?>)`; emits `argoproj.io/v1alpha1 Application`, `metadata.name = app.name`, `spec.project = domain`, derived sync-wave, optional `dependencies`/`contact` annotations.

- [ ] **Step 1: Failing test** — append `render.yaml`:
```yaml
{{- if .Values.aApp }}
{{ include "app-factory.application" (dict "app" .Values.aApp "cluster" "onprem-primary" "environment" "prod" "destination" (dict "name" "in-cluster" "namespace" "harbor")) }}
{{- end }}
```
```yaml
# application_test.yaml
suite: application
templates: [render.yaml]
tests:
  - it: renders Application with project + wave + name
    set: {aApp: {name: harbor, domain: developer-platform, version: "2.11.0", team: platform, tier: standard, dependency-layer: platform, source: {repoURL: x, path: p, targetRevision: main}}}
    asserts:
      - {isKind: {of: Application}}
      - {equal: {path: metadata.name, value: harbor}}
      - {equal: {path: spec.project, value: developer-platform}}
      - {equal: {path: "metadata.annotations['argocd.argoproj.io/sync-wave']", value: "10"}}
```
- [ ] **Step 2:** `helm unittest .` → FAIL
- [ ] **Step 3: Implement**
```yaml
{{- define "app-factory.application" -}}
{{- $a := .app -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ $a.name }}
  namespace: argocd
  labels:
    {{- include "app-factory.labels" (dict "app" $a "cluster" .cluster "environment" .environment "teams" .teams) | nindent 4 }}
  annotations:
    argocd.argoproj.io/sync-wave: {{ include "app-factory.syncwave" (dict "layer" (get $a "dependency-layer")) | quote }}
    {{- with $a.dependencies }}
    platform.pnats.cloud/dependencies: {{ join "," . | quote }}
    {{- end }}
    {{- with $a.contact }}
    platform.pnats.cloud/contact: {{ . | quote }}
    {{- end }}
spec:
  project: {{ $a.domain }}
  destination:
    {{- .destination | toYaml | nindent 4 }}
  source:
    {{- $a.source | toYaml | nindent 4 }}
  syncPolicy:
    {{- $a.syncPolicy | default (dict "automated" (dict "prune" true "selfHeal" true)) | toYaml | nindent 4 }}
{{- end -}}
```
- [ ] **Step 4:** `helm unittest .` → PASS
- [ ] **Step 5: kubeconform the rendered Application**
```bash
helm template platform/app-factory/tests-consumer --set aApp.name=harbor --set aApp.domain=developer-platform --set aApp.version=2.11.0 --set aApp.team=platform --set aApp.tier=standard --set aApp.dependency-layer=platform --set aApp.source.repoURL=x --set aApp.source.path=p --set aApp.source.targetRevision=main | kubeconform -strict -ignore-missing-schemas -
```
Expected: exit 0.
- [ ] **Step 6:** Commit — `test+feat(app-factory): _application renderer`

### Task 7: `_appproject.tpl` — RBAC → groups

**Files:** Create `platform/app-factory/templates/_appproject.tpl`; Test `tests-consumer/tests/appproject_test.yaml`

**Interfaces:** `app-factory.appproject` — input `(dict "domain" <str> "destinations" <list> "sourceRepos" <list?>)`; emits `AppProject` named `<domain>`, 3 roles → `pn-<domain>-{admin,developer,viewer}`.

- [ ] **Step 1: Failing test** — append `render.yaml`:
```yaml
{{- if .Values.pDomain }}
{{ include "app-factory.appproject" (dict "domain" .Values.pDomain "destinations" (list (dict "name" "in-cluster" "namespace" "*"))) }}
{{- end }}
```
```yaml
# appproject_test.yaml
suite: appproject
templates: [render.yaml]
tests:
  - it: renders AppProject with domain-scoped groups
    set: {pDomain: security}
    asserts:
      - {isKind: {of: AppProject}}
      - {equal: {path: metadata.name, value: security}}
      - {equal: {path: "metadata.labels['app.kubernetes.io/part-of']", value: security}}
      - {equal: {path: spec.roles[0].groups[0], value: pn-security-admin}}
```
- [ ] **Step 2:** `helm unittest .` → FAIL
- [ ] **Step 3: Implement**
```yaml
{{- define "app-factory.appproject" -}}
{{- $d := .domain -}}
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: {{ $d }}
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: {{ $d | quote }}
spec:
  sourceRepos:
    {{- .sourceRepos | default (list "*") | toYaml | nindent 4 }}
  destinations:
    {{- .destinations | toYaml | nindent 4 }}
  roles:
    - name: admin
      groups: ["pn-{{ $d }}-admin"]
      policies: ["p, proj:{{ $d }}:admin, applications, *, {{ $d }}/*, allow"]
    - name: developer
      groups: ["pn-{{ $d }}-developer"]
      policies: ["p, proj:{{ $d }}:developer, applications, sync, {{ $d }}/*, allow"]
    - name: viewer
      groups: ["pn-{{ $d }}-viewer"]
      policies: ["p, proj:{{ $d }}:viewer, applications, get, {{ $d }}/*, allow"]
{{- end -}}
```
- [ ] **Step 4:** `helm unittest .` → PASS
- [ ] **Step 5:** Commit — `test+feat(app-factory): _appproject RBAC->groups`

### Task 8: Config schema + app-entry JSON Schema + full gate

**Files:** Create `platform/app-factory/values.schema.json`, `platform/app-factory/schemas/app-entry.schema.json`

- [ ] **Step 1: Factory config schema** (copy from `docs/design/app-factory-values-schema.md` §5) → `platform/app-factory/values.schema.json`.
- [ ] **Step 2: App-entry schema** (copy from §3) → `platform/app-factory/schemas/app-entry.schema.json`.
- [ ] **Step 3: Validate both are valid JSON**
```bash
python3 -c "import json; [json.load(open(f)) for f in ['platform/app-factory/values.schema.json','platform/app-factory/schemas/app-entry.schema.json']]; print('schemas OK')"
```
- [ ] **Step 4: Full suite + lint**
```bash
cd platform/app-factory/tests-consumer && helm dependency build && helm unittest . && cd - && helm lint platform/app-factory
```
Expected: all suites pass; `app-factory` lints (schemas validate the empty factory values).
- [ ] **Step 5: Commit + push**
```bash
git add platform/app-factory
git -c user.email=snoorullah@proficientnow.com -c user.name="Shaik Noorullah" commit -m "feat(app-factory): config + app-entry JSON schemas + full suite green"
git -c credential.helper='!gh auth git-credential' push https://github.com/ProficientnowTech/pn-platform.git HEAD:refs/heads/main
```
- [ ] **Step 6:** Verify remote `main` == local `HEAD`.

---

## Self-review
- **Taxonomy coverage:** all 9 labels stamped (T5); required+enum+pattern+team enforcement (T4); derived sync-wave (T3/T6); Application (T6) + AppProject RBAC→groups (T7); JSON schemas (T8). `environment`/`cluster` are context inputs (T4/T5/T6), matching the values-schema authored-vs-context split.
- **Hyphenated keys:** `dr-role`/`dependency-layer` read via `get` everywhere (T4/T5/T6) — never dot-access.
- **Placeholders:** none — every template + test is complete code; the schema files are copied verbatim from the committed design.
- **Consistency:** helper names (`app-factory.{enums,syncwave,validate,labels,application,appproject}`) and their `(dict …)` inputs match across Interfaces blocks and implementations.
