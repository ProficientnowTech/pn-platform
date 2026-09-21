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
{{- /* dependency-layer-order — the intra-layer ordering primitive a same-layer dependency edge
     (below) compiles into. Validated unconditionally, not just when an edge uses it, so a typo'd
     or nonsensical value fails loudly here instead of silently landing on app-factory.syncwave
     (which enforces the upper bound against the ACTUAL next-layer gap; this only guards the shape). */ -}}
{{- if hasKey $a "dependency-layer-order" -}}
{{- $rawOrder := get $a "dependency-layer-order" -}}
{{- if lt (int $rawOrder) 0 -}}{{- fail (printf "app-factory: app %q dependency-layer-order must be a non-negative integer (got %v)" $n $rawOrder) -}}{{- end -}}
{{- end -}}
{{- if and (hasKey $a "dependencies") (hasKey . "index") -}}
{{- $order := dict "foundation" 0 "core" 1 "platform" 2 "application" 3 -}}
{{- $mine := get $order (get $a "dependency-layer") -}}
{{- range $d := $a.dependencies -}}
{{- if not (hasKey $.index $d) -}}{{- fail (printf "app-factory: app %q depends on unknown %q" $n $d) -}}{{- end -}}
{{- $depLayer := get $.index $d -}}
{{- $depLayerIdx := int (get $order $depLayer) -}}
{{- if gt $depLayerIdx (int $mine) -}}
{{- /* A declared dependency must live in a STRICTLY EARLIER layer, or a STRICTLY LATER layer's
     dependency (the case this branch rejects). This is unchanged monotonicity: an app can never
     depend on something that syncs after it. */ -}}
{{- fail (printf "app-factory: app %q (layer %s) declares a dependency on %q at layer %s — a dependency must be in a STRICTLY EARLIER layer, or it is documentation and not ordering" $n (get $a "dependency-layer") $d $depLayer) -}}
{{- else if eq $depLayerIdx (int $mine) -}}
{{- /* Same-layer edge. `ge` used to reject this outright (PLAN-P5 §4.B3, 2026-09-04): an edge
     that doesn't cross a layer boundary produces the IDENTICAL sync-wave for both apps, ArgoCD
     applies them concurrently, and the edge is a comment, not ordering — exactly how
     ingress-gateway->envoy-gateway shipped broken that day. But banning same-layer edges outright
     just pushed the real, load-bearing order (proxmox-storage MOUNTS the secret
     proxmox-csi-config renders, both `foundation`) back into a prose comment in
     values-onprem.yaml — declared nowhere, enforced by nobody, correct by luck (t33).

     So: a same-layer edge is DECLARABLE here, but ONLY when it is also ENFORCED — this app must
     carry a positive `dependency-layer-order`, which app-factory.syncwave compiles into an actual,
     later sync-wave than the layer's base (where an undeclared dependency sits by default, order
     0). Without that, the edge still fails: it would still be a silent no-op, the exact bug this
     rule exists to prevent. */ -}}
{{- $mineOrder := int (get $a "dependency-layer-order" | default 0) -}}
{{- if le $mineOrder 0 -}}
{{- fail (printf "app-factory: app %q (layer %s) declares a same-layer dependency on %q — set dependency-layer-order to a positive integer (and leave %q's at the default 0) so the edge compiles to a real, later sync-wave, or it is documentation and not ordering" $n (get $a "dependency-layer") $d $d) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
