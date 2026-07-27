{{- define "app-factory.syncwave" -}}
{{- $m := dict "foundation" "-25" "core" "-5" "platform" "10" "application" "30" -}}
{{- if not (hasKey $m .layer) -}}{{- fail (printf "app-factory: unknown dependency-layer %q" .layer) -}}{{- end -}}
{{- get $m .layer -}}
{{- end -}}
