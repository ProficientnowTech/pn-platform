{{- define "app-factory.syncwave" -}}
{{- $layers := list "foundation" "core" "platform" "application" -}}
{{- $bases := dict "foundation" -25 "core" -5 "platform" 10 "application" 30 -}}
{{- $layer := .layer -}}
{{- if not (hasKey $bases $layer) -}}{{- fail (printf "app-factory: unknown dependency-layer %q" $layer) -}}{{- end -}}
{{- /* dependency-layer-order (t33) shifts an app LATER within its own layer's wave, so a
     same-layer dependency edge (app-factory.validate) becomes a real, ArgoCD-enforced ordering
     instead of two Applications syncing at the identical wave. The upper bound is derived from the
     ACTUAL gap to the next layer's base — not a hardcoded constant — so a future change to the
     layer spacing fails loudly here instead of silently letting an intra-layer app's wave collide
     with (or leapfrog past) the next layer.

     Type-guarded the same way as app-factory.validate, and independently: app-factory.application
     calls this directly, so a caller that skips validate (or a future one) must not be able to
     silently coerce a bool/float/string into an order via Sprig's `int`. */ -}}
{{- $rawOrder := .order | default 0 -}}
{{- $k := kindOf $rawOrder -}}
{{- if not (or (eq $k "float64") (eq $k "int") (eq $k "int64")) -}}
{{- fail (printf "app-factory: dependency-layer-order must be a non-negative integer, got %s %v" $k $rawOrder) -}}
{{- end -}}
{{- if and (eq $k "float64") (ne $rawOrder (floor $rawOrder)) -}}
{{- fail (printf "app-factory: dependency-layer-order must be a whole number, got %v" $rawOrder) -}}
{{- end -}}
{{- $order := int $rawOrder -}}
{{- if lt $order 0 -}}{{- fail (printf "app-factory: dependency-layer-order %d must be >= 0" $order) -}}{{- end -}}
{{- $wave := add (get $bases $layer) $order -}}
{{- range $idx, $l := $layers -}}
{{- if and (eq $l $layer) (lt (add $idx 1) (len $layers)) -}}
{{- $next := index $layers (add $idx 1) -}}
{{- $nextBase := get $bases $next -}}
{{- if ge $wave $nextBase -}}{{- fail (printf "app-factory: dependency-layer-order %d pushes layer %q's sync-wave to %d, which reaches the next layer %q (base %d) — lower the order" $order $layer $wave $next $nextBase) -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- $wave -}}
{{- end -}}
