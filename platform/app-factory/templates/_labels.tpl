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
