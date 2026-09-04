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
  {{- /* Resource whitelists. ArgoCD treats an ABSENT clusterResourceWhitelist as deny-all for
       cluster-scoped resources, so a project rendered without one cannot host any app that creates
       a CRD, ClusterRole, Namespace or StorageClass — i.e. most platform apps. Emitting nothing was
       therefore not a neutral default, it was a broken one.
       `clusterResources` is REQUIRED so the deny-all is never reached by accident; pass an explicit
       empty list for a project that genuinely should own no cluster-scoped resources (the app tier).
       `namespaceResources` defaults to '*' — namespaced blast radius is already bounded by
       `destinations`, and enumerating every namespaced kind a Helm chart may emit is where this
       tightening breaks in practice. */ -}}
  {{- if not (hasKey . "clusterResources") }}
  {{- fail (printf "app-factory: appproject %q must set clusterResources (pass [] for none) — an absent whitelist is deny-all, not permissive" $d) }}
  {{- end }}
  clusterResourceWhitelist:
    {{- if .clusterResources }}
    {{- .clusterResources | toYaml | nindent 4 }}
    {{- else }} []
    {{- end }}
  namespaceResourceWhitelist:
    {{- .namespaceResources | default (list (dict "group" "*" "kind" "*")) | toYaml | nindent 4 }}
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
