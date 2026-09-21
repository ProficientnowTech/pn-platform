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
     (which enforces the upper bound against the ACTUAL next-layer gap; this only guards the shape).

     kindIs BEFORE any int conversion — Sprig's `int` (cast.ToInt) coerces instead of erroring: a
     bool silently becomes 0/1, a non-numeric string silently becomes 0. That is precisely the
     silent-no-op failure mode this field exists to prevent, so it is checked here, not assumed.
     A real values-file integer arrives as Go kind "float64" (Helm's YAML loader round-trips
     through JSON, which has no distinct integer type) — "int"/"int64" can still occur via --set
     or a caller-built dict, so both are accepted; the float64 case is then required to have no
     fractional part. */ -}}
{{- if hasKey $a "dependency-layer-order" -}}
{{- $rawOrder := get $a "dependency-layer-order" -}}
{{- $k := kindOf $rawOrder -}}
{{- if not (or (eq $k "float64") (eq $k "int") (eq $k "int64")) -}}
{{- fail (printf "app-factory: app %q dependency-layer-order must be a non-negative integer, got %s %v" $n $k $rawOrder) -}}
{{- end -}}
{{- if and (eq $k "float64") (ne $rawOrder (floor $rawOrder)) -}}
{{- fail (printf "app-factory: app %q dependency-layer-order must be a whole number, got %v" $n $rawOrder) -}}
{{- end -}}
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

     So: a same-layer edge is DECLARABLE here, but ONLY when it is also ENFORCED. "This app's
     order is merely positive" is NOT enough on its own — that still lets two defects through:
     equal orders (A=1, B=1) still render the IDENTICAL wave, and an inverted edge (depender=1,
     dependency=5) passes and renders BACKWARDS — worse than the old unenforced no-op, because it
     now looks ordered while running the wrong way. The only real check is pairwise: this app's
     order must be STRICTLY GREATER than the SPECIFIC dependency's own order.

     That comparison needs the dependency's order, not just its layer — an `orderIndex`
     (name -> order), built by the consumer alongside its existing name -> layer `index` and
     passed in the same way (`platform/catalogue/templates/apps.yaml` does, in this repo). When a
     caller passes one, it is enforced pairwise. When it doesn't (a consumer that hasn't been
     updated yet, or a caller exercising the base library on its own), this falls back to the
     weaker "just be positive" check so the library stays usable without it. */ -}}
{{- $mineOrder := int (get $a "dependency-layer-order" | default 0) -}}
{{- if hasKey $ "orderIndex" -}}
{{- $depOrder := int (get $.orderIndex $d | default 0) -}}
{{- if eq $mineOrder $depOrder -}}
{{- fail (printf "app-factory: app %q (layer %s) same-layer dependency-layer-order %d is not strictly greater than %q's dependency-layer-order %d — equal orders render the IDENTICAL sync-wave, which is the no-op this rule exists to prevent" $n (get $a "dependency-layer") $mineOrder $d $depOrder) -}}
{{- else if lt $mineOrder $depOrder -}}
{{- fail (printf "app-factory: app %q (layer %s) same-layer dependency-layer-order %d is not strictly greater than %q's dependency-layer-order %d — %s would sync BEFORE the dependency it declares, which is backwards" $n (get $a "dependency-layer") $mineOrder $d $depOrder $n) -}}
{{- end -}}
{{- else if le $mineOrder 0 -}}
{{- fail (printf "app-factory: app %q (layer %s) declares a same-layer dependency on %q — set dependency-layer-order to a positive integer (and leave %q's at the default 0) so the edge compiles to a real, later sync-wave, or it is documentation and not ordering" $n (get $a "dependency-layer") $d $d) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
