{{- define "app-factory.application" -}}
{{- $a := .app -}}
{{- /* source/sources are mutually exclusive and exactly one is required. Checked HERE, not in
     app-factory.validate: validate is metadata-only by contract and existing callers invoke it on
     entries that carry no source at all. */ -}}
{{- $hasSource := hasKey $a "source" -}}{{- $hasSources := hasKey $a "sources" -}}
{{- if and $hasSource $hasSources -}}{{- fail (printf "app-factory: app %q sets BOTH source and sources (mutually exclusive)" $a.name) -}}{{- end -}}
{{- if not (or $hasSource $hasSources) -}}{{- fail (printf "app-factory: app %q must set exactly one of source or sources" $a.name) -}}{{- end -}}
{{- if $hasSources -}}{{- if not (kindIs "slice" $a.sources) -}}{{- fail (printf "app-factory: app %q sources must be a list" $a.name) -}}{{- end -}}{{- end -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ $a.name }}
  namespace: argocd
  {{- /* resources-finalizer makes deleting an Application cascade-delete the resources it owns.
       In the FLAT model this is load-bearing, not decoration: there is no umbrella owning these
       apps, so removing an entry from the catalogue prunes the Application — and without the
       finalizer its workloads are silently ORPHANED, still running, owned by nothing.
       Opt-in per app, because it is also the mechanism that makes a careless prune destructive. */ -}}
  {{- if $a.finalizer }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  {{- end }}
  labels:
    {{- include "app-factory.labels" (dict "app" $a "cluster" .cluster "environment" .environment "teams" .teams) | nindent 4 }}
  annotations:
    argocd.argoproj.io/sync-wave: {{ include "app-factory.syncwave" (dict "layer" (get $a "dependency-layer")) | quote }}
    {{- include "app-factory.kappordering" (dict "layer" (get $a "dependency-layer")) | nindent 4 }}
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
  {{- /* ArgoCD multi-source. Required by real platform apps: the `$values` pattern (an upstream
       helm chart + this git repo as `ref: values` so valueFiles can be version-controlled apart
       from the chart), and apps that render several paths under one Application. Six of the twelve
       proven live apps need it, so single-source-only made the factory unable to express the
       cluster it is meant to describe. `source` and `sources` are mutually exclusive — enforced in
       app-factory.validate. */ -}}
  {{- if hasKey $a "sources" }}
  sources:
    {{- $a.sources | toYaml | nindent 4 }}
  {{- else }}
  source:
    {{- $a.source | toYaml | nindent 4 }}
  {{- end }}
  syncPolicy:
    {{- $a.syncPolicy | default (dict "automated" (dict "prune" true "selfHeal" true)) | toYaml | nindent 4 }}
  {{- /* ignoreDifferences — required for charts that render EMPTY collections. Kubernetes strips
       `imagePullSecrets: []`, `nodeSelector: {}`, `tolerations: []` etc. on apply, so the field is
       present in desired and absent in live and the app reports OutOfSync forever while being
       perfectly healthy. Observed on altinity-clickhouse-operator 0.24.1, 2026-09-04.
       ServerSideApply does NOT fix this: the field never lands, so there is nothing to own. */ -}}
  {{- with $a.ignoreDifferences }}
  ignoreDifferences:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
