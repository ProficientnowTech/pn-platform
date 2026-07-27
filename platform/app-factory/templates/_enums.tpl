{{- define "app-factory.enums" -}}
{{ dict
  "domain" (list "infrastructure" "storage" "databases" "security" "monitoring" "developer-platform" "data-streaming" "ml-infra" "application" "backup-dr")
  "environment" (list "dev" "staging" "prod" "preview")
  "tier" (list "critical" "high" "standard" "low")
  "dr-role" (list "none" "source" "replica")
  "lifecycle" (list "active" "experimental" "deprecated")
  "dependency-layer" (list "foundation" "core" "platform" "application")
  "cluster" (list "onprem-primary" "contabo-standby" "azure-dr")
  | toJson }}
{{- end -}}
