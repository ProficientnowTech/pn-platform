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
{{- /* A declared dependency must live in a STRICTLY EARLIER layer. `gt` (later-only) let
     same-layer edges pass silently, which is how two real ordering bugs shipped on 2026-09-04:
     ingress-gateway declared `dependencies: [envoy-gateway]` while BOTH sat at `platform`, so the
     edge was documentation with no effect — the two synced concurrently and ingress-gateway failed
     on "could not find GatewayClass". Per PLAN-P5 §4.B3: "An edge that does not cross a layer
     boundary is documentation, not ordering." If two apps genuinely belong in the same layer, do
     not declare an edge between them — say why in a comment instead. */ -}}
{{- if ge (int (get $order (get $.index $d))) (int $mine) -}}{{- fail (printf "app-factory: app %q (layer %s) declares a dependency on %q at layer %s — a dependency must be in a STRICTLY EARLIER layer, or it is documentation and not ordering" $n (get $a "dependency-layer") $d (get $.index $d)) -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
