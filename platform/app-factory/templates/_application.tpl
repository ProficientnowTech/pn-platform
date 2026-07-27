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
